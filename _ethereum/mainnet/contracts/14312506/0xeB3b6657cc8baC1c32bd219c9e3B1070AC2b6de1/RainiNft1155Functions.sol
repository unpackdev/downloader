// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./ERC1155.sol";
import "./IERC1155MetadataURI.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";

interface IStakingPool {
  function balanceOf(address _owner) external view returns (uint256 balance);
  function burn(address _owner, uint256 _amount) external;
}

interface INftStakingPool {
  function getTokenStamina(uint256 _tokenId, address _nftContractAddress) external view returns (uint256 stamina);
  function mergeTokens(uint256 _newTokenId, uint256[] memory _tokenIds, address _nftContractAddress) external;
}

interface IRainiCustomNFT {
  function onTransfered(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
  function onMerged(uint256 _newTokenId, uint256[] memory _tokenId, address _nftContractAddress, uint256[] memory data) external;
  function onMinted(address _to, uint256 _tokenId, uint256 _cardId, uint256 _cardLevel, uint256 _amount, bytes1 _mintedContractChar, uint256 _number, uint256[] memory _data) external;
  function uri(uint256 id) external view returns (string memory);
}

interface IRainiNft1155 is IERC1155 {
  struct CardLevel {
    uint64 conversionRate; // number of base tokens required to create
    uint32 numberMinted;
    uint128 tokenId; // ID of token if grouped, 0 if not
    uint32 maxStamina; // The initial and maxiumum stamina for a token
  }

  struct Card {
    uint64 costInUnicorns;
    uint64 costInRainbows;
    uint16 maxMintsPerAddress;
    uint32 maxSupply; // number of base tokens mintable
    uint32 allocation; // number of base tokens mintable with points on this contract
    uint32 mintTimeStart; // the timestamp from which the card can be minted
    bool locked;
    address subContract;
  }
  
  struct TokenVars {
    uint128 cardId;
    uint32 level;
    uint32 number; // to assign a numbering to NFTs
    bytes1 mintedContractChar;
  }

  function maxTokenId() external view returns (uint256);
  function contractChar() external view returns (bytes1);

  function numberMintedByAddress(address _address, uint256 _cardID) external view returns (uint256);

  function burn(address _owner, uint256 _tokenId, uint256 _amount, bool _isBridged) external;

  function getPathUri(uint256 _cardId) view external returns (string memory);

  function cards(uint256 _cardId) external view returns (Card memory);
  function cardLevels(uint256 _cardId, uint256 _level) external view returns (CardLevel memory);
  function tokenVars(uint256 _tokenId) external view returns (TokenVars memory);

  function mint(address _to, uint256 _cardId, uint256 _cardLevel, uint256 _amount, bytes1 _mintedContractChar, uint256 _number, uint256[] memory _data) external;
  function addToNumberMintedByAddress(address _address, uint256 _cardId, uint256 amount) external;
}

contract RainiNft1155Functions is AccessControl, ReentrancyGuard {

  address public nftStakingPoolAddress;

  uint256 public constant POINT_COST_DECIMALS = 1000000000000000000;

  uint256 public rainbowToEth;
  uint256 public unicornToEth;
  uint256 public minPointsPercentToMint;

  mapping(address => bool) public rainbowPools;
  mapping(address => bool) public unicornPools;
  mapping(uint256 => uint256) public mergeFees;

  mapping(uint256 => uint256) public startTimeOverrides;

  uint256 public mintingFeeBasisPointsUnicorns;
  uint256 public mintingFeeBasisPointsRainbows;

  mapping(uint256 => uint256) public maxMintsOverrides;


  IRainiNft1155 nftContract;

  constructor(address _nftContractAddress, address _contractOwner) {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(DEFAULT_ADMIN_ROLE, _contractOwner);
    nftContract = IRainiNft1155(_nftContractAddress);
  }

  modifier onlyOwner() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
    _;
  }

  function addRainbowPool(address _rainbowPool) 
    external onlyOwner {
      rainbowPools[_rainbowPool] = true;
  }

  function removeRainbowPool(address _rainbowPool) 
    external onlyOwner {
      rainbowPools[_rainbowPool] = false;
  }

  function addUnicornPool(address _unicornPool) 
    external onlyOwner {
      unicornPools[_unicornPool] = true;
  }

  function removeUnicornPool(address _unicornPool) 
    external onlyOwner {
      unicornPools[_unicornPool] = false;
  }

  function setEtherValues(uint256 _unicornToEth, uint256 _rainbowToEth, uint256 _minPointsPercentToMint)
     external onlyOwner {
      unicornToEth = _unicornToEth;
      rainbowToEth = _rainbowToEth;
      minPointsPercentToMint = _minPointsPercentToMint;
   }

  function setFees(uint256 _mintingFeeBasisPointsRainbows, uint256 _mintingFeeBasisPointsUnicorns, uint256[] memory _mergeFees) 
    external onlyOwner {
      mintingFeeBasisPointsRainbows =_mintingFeeBasisPointsRainbows;
      mintingFeeBasisPointsUnicorns =_mintingFeeBasisPointsUnicorns;
      for (uint256 i = 1; i < _mergeFees.length; i++) {
        mergeFees[i] = _mergeFees[i];
      }
  }

  function setNftStakingPoolAddress(address _nftStakingPoolAddress)
    external onlyOwner {
      nftStakingPoolAddress = (_nftStakingPoolAddress);
  }

  function setTimeStartOverrides(uint256[] memory _cardId, uint256[] memory _newStartTime) 
    external onlyOwner {
      for (uint256 i = 0; i < _cardId.length; i++) {
        startTimeOverrides[_cardId[i]] = _newStartTime[i];
      }
  }

  function setMaxMintsOverrides(uint256[] memory _cardId, uint256[] memory _newMaxMints) 
    external onlyOwner {
      for (uint256 i = 0; i < _cardId.length; i++) {
        maxMintsOverrides[_cardId[i]] = _newMaxMints[i];
      }
  }

  struct MergeData {
    uint256 cost;
    uint256 totalPointsBurned;
    uint256 currentTokenToMint;
    bool willCallPool;
    bool willCallSubContract;
  }

  function merge(uint256 _cardId, uint256 _level, uint256 _mintAmount, uint256[] memory _tokenIds, uint256[] memory _burnAmounts, uint256[] memory _data) 
    external payable nonReentrant {
      IRainiNft1155.CardLevel memory _cardLevel = nftContract.cardLevels(_cardId, _level);

      require(_level > 0 && _cardLevel.conversionRate > 0, "merge not allowed");

      MergeData memory _locals = MergeData({
        cost: 0,
        totalPointsBurned: 0,
        currentTokenToMint: 0,
        willCallPool: false,
        willCallSubContract: false
      });


      _locals.cost = _cardLevel.conversionRate * _mintAmount;

      uint256[] memory mergedTokensIds;
      INftStakingPool nftStakingPool;
      IRainiCustomNFT subContract;

      _locals.willCallPool = nftStakingPoolAddress != address(0) && _level > 0 && nftContract.cardLevels(_cardId, _level-1).tokenId == 0;
      _locals.willCallSubContract = _cardLevel.tokenId == 0 && nftContract.cards(_cardId).subContract != address(0);
      if (_locals.willCallPool || _locals.willCallSubContract) {
        mergedTokensIds = new uint256[](_tokenIds.length);
        if (_locals.willCallPool) {
          nftStakingPool = INftStakingPool(nftStakingPoolAddress);
        }
        if (_locals.willCallSubContract) {
          subContract = IRainiCustomNFT(nftContract.cards(_cardId).subContract);
        }
      }

      for (uint256 i = 0; i < _tokenIds.length; i++) {
        require(_burnAmounts[i] <= nftContract.balanceOf(_msgSender(), _tokenIds[i]), 'not enough balance');
        IRainiNft1155.TokenVars memory _tempTokenVars =  nftContract.tokenVars(_tokenIds[i]);
        require(_tempTokenVars.cardId == _cardId, "card mismatch");
        require(_tempTokenVars.level < _level, "can only merge into higher levels");
        IRainiNft1155.CardLevel memory _tempCardLevel = nftContract.cardLevels(_tempTokenVars.cardId, _tempTokenVars.level);
        if (_tempTokenVars.level == 0) {
          _locals.totalPointsBurned += _burnAmounts[i];
        } else {
          _locals.totalPointsBurned += _burnAmounts[i] * _tempCardLevel.conversionRate;
        }
        nftContract.burn(_msgSender(), _tokenIds[i], _burnAmounts[i], false);

        if (_locals.willCallPool || _locals.willCallSubContract) {
          mergedTokensIds[i] = _tokenIds[i];
          if (_locals.totalPointsBurned > (_locals.currentTokenToMint + 1) * _cardLevel.conversionRate || i == _tokenIds.length - 1) {
            _locals.currentTokenToMint++;
            if (_locals.willCallPool) {
              nftStakingPool.mergeTokens(_locals.currentTokenToMint + nftContract.maxTokenId(), mergedTokensIds, address(nftContract));
            }
            if (_locals.willCallSubContract) {
              subContract.onMerged(_locals.currentTokenToMint + nftContract.maxTokenId(), mergedTokensIds, address(nftContract), _data);
            }
            if (_locals.currentTokenToMint < _mintAmount) {
              mergedTokensIds = new uint256[](_cardLevel.conversionRate);
            }
          }
        }
      }

      require(_locals.totalPointsBurned == _locals.cost, "wrong no tkns burned");

      require(mergeFees[_level] * _mintAmount <= msg.value, "Not enough ETH");

      (bool success, ) = _msgSender().call{ value: msg.value - mergeFees[_level] * _mintAmount}(""); // refund excess Eth
      require(success, "transfer failed");

      nftContract.mint(_msgSender(), _cardId, _level, _mintAmount, nftContract.contractChar(), 0, _data);
  }

  struct MintWithPointsData {
    uint256 totalPriceRainbows;
    uint256 totalPriceUnicorns;
    uint256 fee;
    uint256 amountEthToWithdraw;
    bool success;
  }
  
  function mintWithPoints(uint256[] memory _cardId, uint256[] memory _amount, bool[] memory _useUnicorns, uint256[][] memory _data, address[] memory _rainbowPools, address[] memory _unicornPools)
    external payable nonReentrant {

    MintWithPointsData memory _locals = MintWithPointsData({
      totalPriceRainbows: 0,
      totalPriceUnicorns: 0,
      fee: 0,
      amountEthToWithdraw: 0,
      success: false
    });

    for (uint256 i = 0; i < _cardId.length; i++) {
      IRainiNft1155.Card memory card =  nftContract.cards(_cardId[i]);
      IRainiNft1155.CardLevel memory cardLevel =  nftContract.cardLevels(_cardId[i], 0);

      require(block.timestamp >= ((startTimeOverrides[_cardId[i]] > 0) ? startTimeOverrides[_cardId[i]] : card.mintTimeStart)
               || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'too early');
      require(nftContract.numberMintedByAddress(_msgSender(), _cardId[i]) + _amount[i]  
                <= ((maxMintsOverrides[_cardId[i]] > 0) ? maxMintsOverrides[_cardId[i]] : card.maxMintsPerAddress), "Max mints reached for address");

      if (cardLevel.numberMinted + _amount[i] > card.allocation) {
        _amount[i] = card.allocation - cardLevel.numberMinted;
      }

      if (_useUnicorns[i]) {
        require(card.costInUnicorns > 0, "unicorns not allowed");
        _locals.totalPriceUnicorns += card.costInUnicorns * _amount[i] * POINT_COST_DECIMALS;
        _locals.fee += (card.costInUnicorns * _amount[i] * POINT_COST_DECIMALS * mintingFeeBasisPointsUnicorns) / (unicornToEth * 10000);
      } else {
        require(card.costInRainbows > 0, "rainbows not allowed");
        _locals.totalPriceRainbows += card.costInRainbows * _amount[i] * POINT_COST_DECIMALS;
        _locals.fee += (card.costInRainbows * _amount[i] * POINT_COST_DECIMALS * mintingFeeBasisPointsRainbows) / (rainbowToEth * 10000);
      }
    }

    _locals.amountEthToWithdraw = 0;
    
    for (uint256 n = 0; n < 2; n++) {
      bool loopTypeUnicorns = n > 0;

      uint256 totalBalance = 0;
      uint256 totalPrice = loopTypeUnicorns ? _locals.totalPriceUnicorns : _locals.totalPriceRainbows;
      uint256 remainingPrice = totalPrice;

      if (totalPrice > 0) {
        uint256 loopLength = loopTypeUnicorns ? _unicornPools.length : _rainbowPools.length;

        require(loopLength > 0, "invalid pools");

        for (uint256 i = 0; i < loopLength; i++) {
          IStakingPool pool;
          if (loopTypeUnicorns) {
            require((unicornPools[_unicornPools[i]]), "invalid unicorn pool");
            pool = IStakingPool(_unicornPools[i]);
          } else {
            require((rainbowPools[_rainbowPools[i]]), "invalid rainbow pool");
            pool = IStakingPool(_rainbowPools[i]);
          }
          uint256 _balance = pool.balanceOf(_msgSender());
          totalBalance += _balance;

          if (totalBalance >=  totalPrice) {
            pool.burn(_msgSender(), remainingPrice);
            remainingPrice = 0;
            break;
          } else {
            pool.burn(_msgSender(), _balance);
            remainingPrice -= _balance;
          }
        }

        if (remainingPrice > 0) {
          uint256 minPoints = (totalPrice * minPointsPercentToMint) / 100;
          require(totalPrice - remainingPrice >= minPoints, "not enough balance");
          uint256 pointsToEth = loopTypeUnicorns ? unicornToEth : rainbowToEth;
          require(msg.value * pointsToEth > remainingPrice, "not enough balance");
          _locals.amountEthToWithdraw += remainingPrice / pointsToEth;
        }
      }
    }

    // Add minting fees
    _locals.amountEthToWithdraw += _locals.fee;

    require(_locals.amountEthToWithdraw <= msg.value);

    (_locals.success, ) = _msgSender().call{ value: msg.value - _locals.amountEthToWithdraw }(""); // refund excess Eth
    require(_locals.success, "transfer failed");

    bool _tokenMinted = false;
    for (uint256 i = 0; i < _cardId.length; i++) {
      if (_amount[i] > 0) {
        nftContract.addToNumberMintedByAddress(_msgSender(), _cardId[i], _amount[i]);
        nftContract.mint(_msgSender(), _cardId[i], 0, _amount[i], nftContract.contractChar(), 0, _data[i]);
        _tokenMinted = true;
      }
    }
    require(_tokenMinted, 'Allocation exhausted');
  }

  // Allow the owner to withdraw Ether payed into the contract
  function withdrawEth(uint256 _amount)
    external onlyOwner {
      require(_amount <= address(this).balance, "not enough balance");
      (bool success, ) = _msgSender().call{ value: _amount }("");
      require(success, "transfer failed");
  }
}