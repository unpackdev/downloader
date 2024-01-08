// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./IERC1155.sol";
import "./AccessControl.sol";
import "./Strings.sol";

import "./IRainiCustomNFT.sol";

interface IRainiNft1155 is IERC1155 {
  
  struct TokenVars {
    uint128 cardId;
    uint32 level;
    uint32 number; // to assign a numbering to NFTs
    bytes1 mintedContractChar;
  }

  function tokenVars(uint256 _tokenId) external view returns (TokenVars memory);
}


contract RainiChildContractv1 is AccessControl, IRainiCustomNFT {

  IRainiNft1155 nftContract;

  bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");

  string public baseUri;

  mapping(uint256 => string) public pathUris;
  mapping(uint256 => bool) public ownerCanEdit;

  mapping(uint256 => uint32[]) public tokenData;

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

  function initCards(uint256[] memory _cardId, string[] memory _pathUri, bool[] memory _ownerCanEdit) 
    external onlyOwner {
      for (uint256 i; i < _cardId.length; i++) {
        pathUris[_cardId[i]] = _pathUri[i];
        ownerCanEdit[_cardId[i]] = _ownerCanEdit[i];
      }
  }

  function setBaseURI(string memory _baseURIString)
    external onlyOwner {
      baseUri = _baseURIString;
  }

    
  function onMinted(address _to, uint256 _tokenId, uint256 _cardId, uint256 _cardLevel, uint256 _amount, bytes1 _mintedContractChar, uint256 _number, uint256[] memory _data) 
    external override onlyEditor {
      if (_data.length > 0) {
        IRainiNft1155.TokenVars memory _tokenVars = nftContract.tokenVars(_tokenId);

        if (_tokenVars.number > 0) {
          uint32[] memory _temp = new uint32[](_data.length);
          for (uint256 i; i < _temp.length; i++) {
            _temp[i] = uint32(_data[i]);
          }
          tokenData[_tokenId] = _temp;
        }
      }
  }

  function onTransfered(address from, address to, uint256 id, uint256 amount, bytes memory data) external override {
  }
  
  function onMerged(uint256 _newTokenId, uint256[] memory _tokenId, address _nftContractAddress, uint256[] memory data) 
    external override {
  }

  function getTokenState(uint256 id) public view override returns (bytes memory) {
    return abi.encode(tokenData[id]);
  }

  function setTokenStates(uint256[] memory id, bytes[] memory state) external override onlyEditor {
    bool isEditor = hasRole(EDITOR_ROLE, _msgSender());

    for (uint256 i; i < id.length; i++) {

      if (!isEditor) {
        IRainiNft1155.TokenVars memory _tokenVars = nftContract.tokenVars(id[i]);
        require(_tokenVars.number > 0 && ownerCanEdit[_tokenVars.cardId] && nftContract.balanceOf(_msgSender(), id[i]) == 1, "can't edit");
      }

      (tokenData[id[i]]) = abi.decode(state[i], (uint32[]));
    }
  }

  function uri(uint256 id) external override view returns (string memory) {
    
    IRainiNft1155.TokenVars memory _tokenVars = nftContract.tokenVars(id);

    string memory query;

    for (uint256 i; i < tokenData[id].length; i++) {
      query = string(abi.encodePacked(query, "&p", Strings.toString(i), "=", Strings.toString(tokenData[id][i]), ""));
    }

    return string(abi.encodePacked(baseUri, pathUris[_tokenVars.cardId], "?c=", _tokenVars.mintedContractChar, "&l=", Strings.toString(_tokenVars.level), "&n=", Strings.toString(_tokenVars.number), query));
  }
}
