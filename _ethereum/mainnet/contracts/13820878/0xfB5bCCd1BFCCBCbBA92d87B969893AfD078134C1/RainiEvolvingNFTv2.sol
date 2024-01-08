// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./IERC1155.sol";
import "./AccessControl.sol";
import "./Strings.sol";

import "./IRainiCustomNFT.sol";

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

  function cardPathUri(uint256 _cardId) view external returns (string memory);

  function cards(uint256 _cardId) external view returns (Card memory);
  function cardLevels(uint256 _cardId, uint256 _level) external view returns (CardLevel memory);
  function tokenVars(uint256 _tokenId) external view returns (TokenVars memory);
}

contract RainiEvolvingNFTv2 is AccessControl, IRainiCustomNFT {

  IRainiNft1155 public nftContract;

  bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");

  string public baseUri;

  struct CardVars {
    uint32 numStates;
    uint32 timePeriod;
    uint32 initTime;
    bool repeats;
    bool resetsOnTransfer;
    bool coreEvolves;
    bool allowTimezoneSet;
    bool allowHemisphereSet;
    bool exists;
  }
  
  struct EvolvingTokenVars {
    uint128 cardId;
    uint32 initTime;
    uint32 lastState;
    bool evolves;
    bool isGrouped;
    bool exists;
  }

  mapping(uint256 => CardVars) public cards;
  mapping(uint256 => EvolvingTokenVars) public tokenVars;

  modifier onlyOwner() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "caller is not an admin");
    _;
  }

  modifier onlyEditor() {
    require(hasRole(EDITOR_ROLE, _msgSender()), "caller is not an editor");
    _;
  }

  constructor (address _nftContractAddress, string memory _uri) {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(EDITOR_ROLE, _nftContractAddress);
    nftContract = IRainiNft1155(_nftContractAddress);
    baseUri = _uri;
  }

  function initCards(
    uint256[] memory _cardId, 
    uint256[] memory _timePeriod, 
    uint256[] memory _numStates, 
    uint256[] memory _initTime, 
    bool[] memory _repeats, 
    bool[] memory _resetsOnTransfer, 
    bool[] memory _coreEvolves, 
    bool[] memory _allowTimezoneSet, 
    bool[] memory _allowHemisphereSet) 
    external onlyOwner {
      for (uint256 i; i < _cardId.length; i++) {
        cards[_cardId[i]] = CardVars({
          numStates: uint32(_numStates[i]),
          timePeriod: uint32(_timePeriod[i]),
          initTime: uint32(_initTime[i]),
          repeats: _repeats[i],
          resetsOnTransfer: _resetsOnTransfer[i],
          coreEvolves: _coreEvolves[i],
          allowTimezoneSet: _allowTimezoneSet[i],
          allowHemisphereSet: _allowHemisphereSet[i],
          exists: true
        });
        uint256 _tokenId = nftContract.cardLevels(_cardId[i], 0).tokenId;
        if (_tokenId != 0) {
          tokenVars[_tokenId] = EvolvingTokenVars({
            cardId: uint128(_cardId[i]),
            initTime: uint32(_coreEvolves[i] ? _initTime[i] : 0),
            lastState: 0,
            evolves: _coreEvolves[i],
            isGrouped: true,
            exists: true
          });
        }
      }
  }

    
  function onMinted(address _to, uint256 _tokenId, uint256 _cardId, uint256 _cardLevel, uint256 _amount, bytes1 _mintedContractChar, uint256 _number, uint256[] memory _data) 
    external override onlyEditor {

      if (tokenVars[_tokenId].exists || !cards[_cardId].exists) {
        return;
      }

      CardVars memory _card = cards[_cardId];

      uint256 _startTime = _card.initTime;

      if (_startTime == 0) {
        _startTime = block.timestamp;
      } else {
        if (_card.allowTimezoneSet) {
          uint256 offset = _data.length > 0 ? _data[0] : 0;
          require (offset < 24 * 60 * 60, 'offset too big');
          _startTime -= offset;
        }

        if (_card.allowHemisphereSet) {
          if (_data.length > 1 && _data[1] == 1) {
            _startTime -= 183 * 24 * 60 * 60;
          }
        }
      }

      tokenVars[_tokenId] = EvolvingTokenVars({
        cardId: uint128(_cardId),
        initTime: uint32(_startTime),
        lastState: 0,
        evolves: _cardLevel > 0 || _card.coreEvolves,
        isGrouped: false,
        exists: true
      });
  }

  function onTransfered(address from, address to, uint256 id, uint256 amount, bytes memory data) external override onlyEditor {
      if (!tokenVars[id].exists) {
        return;
      }
      if (cards[tokenVars[id].cardId].resetsOnTransfer && !tokenVars[id].isGrouped) {
        tokenVars[id].lastState = uint32(getState(id, 0));
        tokenVars[id].initTime = uint32(block.timestamp);
      }
  }
  
  function onMerged(uint256 _newTokenId, uint256[] memory _tokenId, address _nftContractAddress, uint256[] memory data) 
    external override {
  }

  function getState(uint256 _tokenId, uint256 _timeStamp) public view returns (uint256) {

    if (_timeStamp == 0) {
      _timeStamp = block.timestamp;
    }

    EvolvingTokenVars memory _tokenVars =  tokenVars[_tokenId];

    if (!_tokenVars.evolves) {
      return 0;
    }

    CardVars memory _cardVars = cards[_tokenVars.cardId];

    uint256 _timeSinceStart = _timeStamp - _tokenVars.initTime;
    uint256 _state = _timeSinceStart / _cardVars.timePeriod;

    if (_state >= _cardVars.numStates) {
      if (_cardVars.repeats) {
        _state = _state % _cardVars.numStates;
      } else {
        _state = _cardVars.numStates - 1;
      }
    }

    return _state;
  }

  function uri(uint256 id) external view override returns (string memory) {
    IRainiNft1155.TokenVars memory _tokenVars = nftContract.tokenVars(id);
    require(_tokenVars.cardId != 0, "No token for given ID");

    return string(abi.encodePacked(baseUri, nftContract.cardPathUri(_tokenVars.cardId), "/", _tokenVars.mintedContractChar, "l", Strings.toString(_tokenVars.level), "n", Strings.toString(_tokenVars.number), "s", Strings.toString(getState(id, 0)), ".json"));
  }

  function getTokenState(uint256 id) public view override returns (bytes memory) {
    return abi.encode(tokenVars[id]);
  }

  function setTokenStates(uint256[] memory id, bytes[] memory state) external override onlyEditor {
    for (uint256 i; i < id.length; i++) {
      (tokenVars[id[i]]) = abi.decode(state[i], (EvolvingTokenVars));
    }
  }

  function setTokenStates(uint256[] memory id, uint128[] memory cardId, uint32[] memory initTime, uint32[] memory lastState, bool[] memory evolves, bool[] memory isGrouped, bool[] memory exists)
       external onlyOwner {
    for (uint256 i; i < id.length; i++) {
      tokenVars[id[i]] = EvolvingTokenVars(
        cardId[i],
        initTime[i],
        lastState[i],
        evolves[i],
        isGrouped[i],
        exists[i]
      );
    }
  }
}
