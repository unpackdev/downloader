// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./ERC1155.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";

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

contract MultiMerge is AccessControl, ReentrancyGuard {

  IRainiNft1155 public nftContract;
  address public nftStakingPoolAddress;

  struct CardAmount {
    uint32 cardId;
    uint32 amount;
  }

  // cardId => level => cardAmounts
  mapping(uint256 => mapping(uint256 => CardAmount[])) public mergeAmounts;

  mapping(uint256 => uint256) public mergeFees;
  
  constructor(address _nftContractAddress, address _contractOwner) {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(DEFAULT_ADMIN_ROLE, _contractOwner);
    nftContract = IRainiNft1155(_nftContractAddress);
  }

  modifier onlyOwner() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
    _;
  }

  function setFees(uint256[] memory _mergeFees) 
    external onlyOwner {
      for (uint256 i = 1; i < _mergeFees.length; i++) {
        mergeFees[i] = _mergeFees[i];
      }
  }

  function setNftStakingPoolAddress(address _nftStakingPoolAddress)
    external onlyOwner {
      nftStakingPoolAddress = (_nftStakingPoolAddress);
  }

  function setMergeAmounts(uint256[] memory _mintedCardId, uint256[] memory _mintedCardLevel, uint256[][] memory _mergedId, uint256[][] memory _amount) 
    external onlyOwner {
      for (uint256 i = 0; i < _mergedId.length; i++) {
        // mergeAmounts[_mintedCardId[i]][_mintedCardLevel[i]] = new CardAmount[];
        for (uint256 j = 0; j < _mergedId[i].length; j++) {
          mergeAmounts[_mintedCardId[i]][_mintedCardLevel[i]].push(CardAmount({
            cardId: uint32(_mergedId[i][j]),
            amount: uint32(_amount[i][j])
          }));
        }
      }
  }

  struct MergeData {
    uint256 cost;
    uint256 currentCard;
    bool willCallPool;
    bool willCallSubContract;
    bool isFinished;
    bool success;
  }

  function merge(uint256 _cardId, uint256 _level, uint256[] memory _tokenIds, uint256[] memory _burnAmounts, uint256[] memory _data) 
    external payable nonReentrant {
      IRainiNft1155.CardLevel memory _cardLevel = nftContract.cardLevels(_cardId, _level);

      MergeData memory _locals = MergeData({
        cost: 0,
        currentCard: 0,
        willCallPool: false,
        willCallSubContract: false,
        isFinished: false,
        success: false
      });

      CardAmount[] memory cardAmounts = mergeAmounts[_cardId][_level];

      require(cardAmounts.length > 0, 'merge invalid');

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

      CardAmount[] memory cost = cardAmounts;

      for (uint256 i = 0; i < _tokenIds.length; i++) {
        require(_burnAmounts[i] <= nftContract.balanceOf(_msgSender(), _tokenIds[i]), 'not enough balance');
        IRainiNft1155.TokenVars memory _tempTokenVars =  nftContract.tokenVars(_tokenIds[i]);
        require(_tempTokenVars.cardId == cost[_locals.currentCard].cardId, "card mismatch");
        IRainiNft1155.CardLevel memory _tempCardLevel = nftContract.cardLevels(_tempTokenVars.cardId, _tempTokenVars.level);
        if (_tempTokenVars.level == 0) {
          cost[_locals.currentCard].amount -= uint32(_burnAmounts[i]);
        } else {
          cost[_locals.currentCard].amount -= uint32(_burnAmounts[i] * _tempCardLevel.conversionRate);
        }
        nftContract.burn(_msgSender(), _tokenIds[i], _burnAmounts[i], false);

        if (cost[_locals.currentCard].amount == 0) {
          if (_locals.currentCard < cost.length - 1) {
            _locals.currentCard++;
          } else {
            _locals.isFinished = true;
          }
        }

        if (_locals.willCallPool || _locals.willCallSubContract) {
          mergedTokensIds[i] = _tokenIds[i];
          if (_locals.isFinished) {
            
            if (_locals.willCallPool) {
              nftStakingPool.mergeTokens(nftContract.maxTokenId() + 1, mergedTokensIds, address(nftContract));
            }
            if (_locals.willCallSubContract) {
              subContract.onMerged(nftContract.maxTokenId() + 1, mergedTokensIds, address(nftContract), _data);
            }
          }
        }
      }

      require(mergeFees[_level] <= msg.value, "Not enough ETH");
      require(_locals.isFinished, "Not enough tokens");

      (_locals.success, ) = _msgSender().call{ value: msg.value - mergeFees[_level]}(""); // refund excess Eth
      require(_locals.success, "transfer failed");

      nftContract.mint(_msgSender(), _cardId, _level, 1, nftContract.contractChar(), 0, _data);
  }

}