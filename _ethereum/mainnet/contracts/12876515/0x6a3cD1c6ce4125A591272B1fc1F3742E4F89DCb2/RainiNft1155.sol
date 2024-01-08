// "SPDX-License-Identifier: MIT"

pragma solidity ^0.8.3;

import "./ERC1155.sol";
import "./IERC1155MetadataURI.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

interface IStakingPool {
  function balanceOf(address _owner) external view returns (uint256 balance);
  function burn(address _owner, uint256 _amount) external;
}

interface INftStakingPool {
  function getTokenStamina(uint256 _tokenId, address _nftContractAddress) external view returns (uint256 stamina);
  function mergeTokens(uint256 _newTokenId, uint256[] memory _tokenIds, address _nftContractAddress) external;
}

contract RainiNFT1155 is ERC1155, AccessControl, ReentrancyGuard {
  using SafeMath for uint256;

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

  address public nftStakingPoolAddress;

  struct CardLevel {
    uint64 conversionRate; // number of base tokens required to create
    uint32 numberMinted;
    uint128 tokenId; // ID of token if grouped, 0 if not
    uint32 maxStamina; // The initial and maxiumum stamina for a token
  }
  
  uint256 public constant POINT_COST_DECIMALS = 1000000000000000000;

  struct Card {
    uint64 costInUnicorns;
    uint64 costInRainbows;
    uint16 maxMintsPerAddress;
    uint32 maxSupply; // number of base tokens mintable
    uint32 allocation; // number of base tokens mintable with points on this contract
    uint32 mintTimeStart; // the timestamp from which the card can be minted
    string pathUri;
  }

  struct TokenVars {
    uint128 cardId;
    uint32 level;
    uint32 number; // to assign a numbering to NFTs
    bytes1 mintedContractChar;
  }

  uint256 public rainbowToEth;
  uint256 public unicornToEth;
  uint256 public minPointsPercentToMint = 25;

  string public baseUri;
  bytes1 public contractChar;
  string public contractURIString;

  // userId => cardId => count
  mapping(address => mapping(uint256 => uint256)) public numberMintedByAddress; // Number of a card minted by an address

  mapping(address => bool) public rainbowPools;
  mapping(address => bool) public unicornPools;

  uint256 public maxTokenId;
  uint256 public maxCardId;

  address private contractOwner;

  mapping(uint256 => Card) public cards;
  mapping(uint256 => CardLevel[]) public cardLevels;
  mapping(uint256 => uint256) public mergeFees;
  uint256 public mintingFeeBasisPoints;

  mapping(uint256 => TokenVars) public tokenVars;

  //event Minted(address to, uint256 id, uint256 amount);
  event Burned(address owner, uint256 id, uint256 amount);
  event CardsInitialized(uint256[] tokenIds, uint256[] maxSupplys);

  event Merged(address owner, uint256 id, uint256 received);




  constructor(string memory _uri, bytes1 _contractChar, string memory _contractURIString, address _contractOwner) 
    ERC1155(_uri) {
      _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
      _setupRole(DEFAULT_ADMIN_ROLE, _contractOwner);
      _setupRole(MINTER_ROLE, _msgSender());
      _setupRole(BURNER_ROLE, _msgSender());
    baseUri = _uri;
    contractOwner = _contractOwner;
    contractChar = _contractChar;
    contractURIString = _contractURIString;
  }

  modifier onlyOwner() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "caller is not an admin");
    _;
  }

  modifier onlyMinter() {
    require(hasRole(MINTER_ROLE, _msgSender()), "caller is not a minter");
    _;
  }

  modifier onlyBurner() {
    require(hasRole(BURNER_ROLE, _msgSender()), "caller is not a burner");
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

  function setcontractURI(string memory _contractURIString)
    external onlyOwner {
      contractURIString = _contractURIString;
  }

  function setFees(uint256 _mintingFeeBasisPoints, uint256[] memory _mergeFees) 
    external onlyOwner {
      mintingFeeBasisPoints =_mintingFeeBasisPoints;
      for (uint256 i = 1; i < _mergeFees.length; i++) {
        mergeFees[i] = _mergeFees[i];
      }
  }

  function setNftStakingPoolAddress(address _nftStakingPoolAddress)
    external onlyOwner {
      nftStakingPoolAddress = (_nftStakingPoolAddress);
  }

  function getTokenStamina(uint256 _tokenId)
    external view returns (uint256) {
      if (nftStakingPoolAddress == address(0)) {
        TokenVars memory _tokenVars =  tokenVars[_tokenId];
        require(_tokenVars.cardId != 0, "No token for given ID");
        return cardLevels[_tokenVars.cardId][_tokenVars.level].maxStamina;
      } else {
        INftStakingPool nftStakingPool = INftStakingPool(nftStakingPoolAddress);
        return nftStakingPool.getTokenStamina(_tokenId, address(this));
      }
  }

  function getTotalBalance(address _address) 
    external view returns (uint256[][] memory amounts) {
      uint256[][] memory _amounts = new uint256[][](maxTokenId);
      uint256 count;
      for (uint256 i = 1; i <= maxTokenId; i++) {
        uint256 balance = balanceOf(_address, i);
        if (balance != 0) {
          _amounts[count] = new uint256[](2);
          _amounts[count][0] = i;
          _amounts[count][1] = balance;
          count++;
        }
      }

      uint256[][] memory _amounts2 = new uint256[][](count);
      for (uint256 i = 0; i < count; i++) {
        _amounts2[i] = new uint256[](2);
        _amounts2[i][0] = _amounts[i][0];
        _amounts2[i][1] = _amounts[i][1];
      }

      return _amounts2;
  }

  function merge(uint256 _cardId, uint256 _level, uint256 _mintAmount, uint256[] memory _tokenIds, uint256[] memory _burnAmounts) 
    external payable nonReentrant {
      CardLevel memory _cardLevel = cardLevels[_cardId][_level];

      require(_level > 0 && _cardLevel.conversionRate > 0, "merge not allowed");

      uint256 cost = _cardLevel.conversionRate * _mintAmount;

      uint256 totalPointsBurned = 0;

      for (uint256 i = 0; i < _tokenIds.length; i++) {
        require(_burnAmounts[i] <= balanceOf(_msgSender(), _tokenIds[i]), "not enough balance");
        TokenVars memory _tempTokenVars =  tokenVars[_tokenIds[i]];
        require(_tempTokenVars.cardId == _cardId, "card mismatch");
        require(_tempTokenVars.level < _level, "can only merge into higher levels");
        CardLevel memory _tempCardLevel = cardLevels[_tempTokenVars.cardId][_tempTokenVars.level];
        if (_tempTokenVars.level == 0) {
          totalPointsBurned += _burnAmounts[i];
        } else {
          totalPointsBurned += _burnAmounts[i] * _tempCardLevel.conversionRate;
        }
        _burn(_msgSender(), _tokenIds[i], _burnAmounts[i]);
      }

      require(totalPointsBurned == cost, "wrong number of tokens burned");

      require(mergeFees[_level] * _mintAmount <= msg.value, "Not enough ETH");

      (bool success, ) = _msgSender().call{ value: msg.value - mergeFees[_level] * _mintAmount}(""); // refund excess Eth
      require(success, "transfer failed");

      if (nftStakingPoolAddress != address(0) && _level > 0 && cardLevels[_cardId][_level-1].tokenId == 0) {
        INftStakingPool nftStakingPool = INftStakingPool(nftStakingPoolAddress);
        uint256 nextTokenId = maxTokenId;
        uint256[] memory mergedTokensIds = new uint256[](_cardLevel.conversionRate);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
          if (i > 0 && i%_cardLevel.conversionRate == 0) {
            nextTokenId++;
            nftStakingPool.mergeTokens(nextTokenId, mergedTokensIds, address(this));
            mergedTokensIds = new uint256[](_cardLevel.conversionRate);
          }
          mergedTokensIds[i%_cardLevel.conversionRate] = _tokenIds[i];
        }
      }

      _mintToken(_msgSender(), _cardId, _level, _mintAmount, contractChar, 0);
  }

  function initCards(uint256[] memory _costInUnicorns, uint256[] memory _costInRainbows, uint256[] memory _maxMintsPerAddress,  uint16[] memory _maxSupply, uint256[] memory _allocation, string[] memory _pathUri, uint32[] memory _mintTimeStart, uint16[][] memory _conversionRates, bool[][] memory _isGrouped, uint256[][] memory _maxStamina)
    external onlyOwner() {

      require(_costInUnicorns.length == _costInRainbows.length);
      require(_costInUnicorns.length == _maxMintsPerAddress.length);
      require(_costInUnicorns.length == _pathUri.length);
      require(_costInUnicorns.length == _maxSupply.length);
      require(_costInUnicorns.length == _allocation.length);

      uint256 _maxCardId = maxCardId;
      uint256 _maxTokenId = maxTokenId;

      for (uint256 i; i < _costInUnicorns.length; i++) {
        require(_conversionRates[i].length == _isGrouped[i].length);

        _maxCardId++;
        cards[_maxCardId] = Card({
            costInUnicorns: uint64(_costInUnicorns[i]),
            costInRainbows: uint64(_costInRainbows[i]),
            maxMintsPerAddress: uint16(_maxMintsPerAddress[i]),
            maxSupply: uint32(_maxSupply[i]),
            allocation: uint32(_allocation[i]),
            mintTimeStart: uint32(_mintTimeStart[i]),
            pathUri: _pathUri[i]
          });
        
        for (uint256 j = 0; j < _conversionRates[i].length; j++) {
          uint256 _tokenId = 0;

          if (_isGrouped[i][j]) {
            _maxTokenId++;
            _tokenId = _maxTokenId;
            tokenVars[_maxTokenId] = TokenVars({
              cardId: uint128(_maxCardId),
              level: uint32(j),
              number: 0,
              mintedContractChar: contractChar
            });
          }

          cardLevels[_maxCardId].push(CardLevel({
            conversionRate: uint64(_conversionRates[i][j]),
            numberMinted: 0,
            tokenId: uint128(_tokenId),
            maxStamina: uint32(_maxStamina[i][j])
          }));
        }
        
      }

      maxTokenId = _maxTokenId;
      maxCardId = _maxCardId;
  }
  
  function _mintToken(address _to, uint256 _cardId, uint256 _cardLevel, uint256 _amount, bytes1 _mintedContractChar, uint256 _number) private {
    Card memory card = cards[_cardId];
    CardLevel memory cardLevel = cardLevels[_cardId][_cardLevel];


    require(_cardLevel > 0 || cardLevel.numberMinted + _amount <= card.maxSupply, "total supply reached.");

    if (cardLevel.tokenId != 0) {
      _mint(_to, _cardId, _amount, "");
    } else {
      for (uint256 i = 0; i < _amount; i++) {
        uint256 num;
        if (_number == 0) {
          cardLevel.numberMinted += 1;
          num = cardLevel.numberMinted;
        } else {
          num = _number;
        }

        uint256 _maxTokenId = maxTokenId;
        _maxTokenId++;
        _mint(_to, _maxTokenId, 1, "");
        tokenVars[_maxTokenId] = TokenVars({
          cardId: uint128(_cardId),
          level: uint32(_cardLevel),
          number: uint32(num),
          mintedContractChar: _mintedContractChar
        });

        maxTokenId = _maxTokenId;
      }
    }

    cardLevels[_cardId][_cardLevel].numberMinted += uint32(_amount);
    //emit Minted(_to, _cardId, _amount);
  }

  function mint(address _to, uint256 _cardId, uint256 _cardLevel, uint256 _amount, bytes1 _mintedContractChar, uint256 _number) 
    external onlyMinter {
      _mintToken(_to, _cardId, _cardLevel, _amount, _mintedContractChar, _number);
  }

  function burn(uint256 _tokenId, uint256 _amount, address _owner) 
    external onlyBurner {
      require(_amount <= balanceOf(_owner, _tokenId), "not enough balance");

      _burn(_owner, _tokenId, _amount);

      emit Burned(_owner, _tokenId, _amount);
  }

  function supportsInterface(bytes4 interfaceId) 
    public virtual override(ERC1155, AccessControl) view returns (bool) {
        return interfaceId == type(IERC1155).interfaceId
            || interfaceId == type(IERC1155MetadataURI).interfaceId
            || interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
  }

  function mintWithPoints(uint256[] memory _cardId, uint256[] memory _amount, bool[] memory _useUnicorns, address[] memory _rainbowPools, address[] memory _unicornPools)
    external payable nonReentrant {

    uint256 _totalPriceRainbows = 0;
    uint256 _totalPriceUnicorns = 0;
    uint256 _fee = 0;

    for (uint256 i = 0; i < _cardId.length; i++) {
      Card memory card =  cards[_cardId[i]];
      CardLevel memory cardLevel =  cardLevels[_cardId[i]][0];

      require(block.timestamp >= card.mintTimeStart, "Card not yet mintable");
      require(cardLevel.numberMinted + _amount[i] <= card.allocation, "Not enough tokens in supply");
      require(numberMintedByAddress[_msgSender()][_cardId[i]] + _amount[i] <= card.maxMintsPerAddress, "Max mints reached for address");

      if (_useUnicorns[i]) {
        require(card.costInUnicorns > 0, "unicorns not allowed");
        _totalPriceUnicorns += card.costInUnicorns * _amount[i] * POINT_COST_DECIMALS;
      } else {
        require(card.costInRainbows > 0, "rainbows not allowed");
        _totalPriceRainbows += card.costInRainbows * _amount[i] * POINT_COST_DECIMALS;
      }

      if (card.costInRainbows > 0) {
        _fee += (card.costInRainbows * _amount[i] * POINT_COST_DECIMALS * mintingFeeBasisPoints) / (rainbowToEth * 10000);
      } else {
        _fee += (card.costInUnicorns * _amount[i] * POINT_COST_DECIMALS * mintingFeeBasisPoints) / (unicornToEth * 10000);
      }
    }

    uint256 _amountEthToWithdraw = 0;
    
    for (uint256 n = 0; n < 2; n++) {
      bool loopTypeUnicorns = n > 0;

      uint256 totalBalance = 0;
      uint256 totalPrice = loopTypeUnicorns ? _totalPriceUnicorns : _totalPriceRainbows;
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
          _amountEthToWithdraw += remainingPrice / pointsToEth;
        }
      }
    }

    // Add minting fees
    _amountEthToWithdraw += _fee;

    require(_amountEthToWithdraw <= msg.value, "Not enough ETH");

    (bool success, ) = _msgSender().call{ value: msg.value - _amountEthToWithdraw }(""); // refund excess Eth
    require(success, "transfer failed");

    for (uint256 i = 0; i < _cardId.length; i++) {
      numberMintedByAddress[_msgSender()][_cardId[i]] += _amount[i];

      _mintToken(_msgSender(), _cardId[i], 0, _amount[i], contractChar, 0);
    }
  }

  function uri(uint256 id) public view virtual override returns (string memory) {
    TokenVars memory _tokenVars =  tokenVars[id];
    require(_tokenVars.cardId != 0, "No token for given ID");
    return string(abi.encodePacked(baseUri, cards[_tokenVars.cardId].pathUri, "/", _tokenVars.mintedContractChar, "l", uint2str(_tokenVars.level), "n", uint2str(_tokenVars.number), ".json"));
  }

  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
        return "0";
    }
    uint j = _i;
    uint len;
    while (j != 0) {
        len++;
        j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len;
    while (_i != 0) {
        k = k-1;
        uint8 temp = (48 + uint8(_i - _i / 10 * 10));
        bytes1 b1 = bytes1(temp);
        bstr[k] = b1;
        _i /= 10;
    }
    return string(bstr);
  }

  function contractURI() public view returns (string memory) {
      return contractURIString; //"ipfs://ipfs/QmcFSxsmHKSF7qLipio8RuE9Mh61bP2U5VdDg54zCV7W5g";
  }

  function owner() public view virtual returns (address) {
    return contractOwner;
  }

  // Allow the owner to withdraw Ether payed into the contract
  function withdrawEth(uint256 _amount)
    external onlyOwner {
      require(_amount <= address(this).balance, "not enough balance");
      (bool success, ) = _msgSender().call{ value: _amount }("");
      require(success, "transfer failed");
  }

}