// SPDX-License-Identifier: GPL-3.0

// Presented by Wildxyz

pragma solidity ^0.8.17;

import "./Strings.sol";
import "./Base64.sol";

import "./MetadataBase.sol";

abstract contract MetadataP5JS is MetadataBase {
  string constant public LIBRARY_NAME = 'p5-v1.5.0.min.js.gz';

  address public nftAddress;

  string public name;
  string public description;

  string public tokenImageURI;

  mapping(uint256 => bytes32) private tokenHashes;

  error OnlyNFTContract();

  modifier onlyNFT() {
    if (msg.sender != nftAddress) revert OnlyNFTContract();
    _;
  }

  constructor(address _fileStore, address _scriptStorage, address _nftAddress, string memory _name, string memory _description, string memory _tokenImageURI) MetadataBase(_fileStore, _scriptStorage, LIBRARY_NAME)
  {
    name = _name;
    description = _description;
    tokenImageURI = _tokenImageURI;
    nftAddress = _nftAddress;
  }

  function _tokenHTMLFromHash(bytes32 _hash) internal view virtual returns (string memory) {
    return string(abi.encodePacked(
      '<html><head><meta charset="utf-8"><script>var tokenData = { hash: "',
      _toHex(_hash),
      '","attributes":[',
      _generateTraits(_hash),
      '] };</script>',
      "<script type=\"text/javascript+gzip\" src=\"data:text/javascript;base64,",
      getLibrary(),
      "\"></script>"
      "<script src=\"data:text/javascript;base64,",
      getDecompressor(),
      "\"></script><script>",
      getScript(),
      '</script><style type="text/css">body { margin: 0; padding: 0; } canvas { padding: 0; margin: auto; display: block; position: absolute; top: 0; bottom: 0; left: 0; right: 0; }</style></head></html>'
    ));
  }

  function _tokenHTML(uint256 _tokenId) internal view virtual returns (string memory) {
    return _tokenHTMLFromHash(tokenHashes[_tokenId]);
  }

  // only NFT

  function generateTokenHash(uint256 _tokenId, address _to) public virtual onlyNFT {
    tokenHashes[_tokenId] = keccak256(abi.encode(_tokenId, _to, block.number, block.timestamp, block.prevrandao, blockhash(block.number - 1), address(this)));
  }

  // only owner

  function setName(string memory _name) public virtual onlyOwner {
    name = _name;
  }

  function setDescription(string memory _description) public virtual onlyOwner {
    description = _description;
  }

  function setTokenImageURI(string memory _tokenImageURI) public virtual onlyOwner {
    tokenImageURI = _tokenImageURI;
  }

  function setNFTAddress(address _nftAddress) public virtual onlyOwner {
    nftAddress = _nftAddress;
  }

  // overrides

  function setScriptStorage(address _scriptStorage) public virtual override onlyOwner {
    _setScriptStorage(_scriptStorage);
  }

  function setFileStore(address _fileStore) public virtual override onlyOwner {
    _setFileStore(_fileStore);
  }

  function setLibraryName(string memory _libraryName) public virtual override onlyOwner {
    _setLibraryName(_libraryName);
  }

  function setDecompressorName(string memory _decompressorName) public virtual override onlyOwner {
    _setDecompressorName(_decompressorName);
  }

  // public

  function getTokenHash(uint256 _tokenId) public view virtual returns (bytes32) {
    return tokenHashes[_tokenId];
  }

  function tokenHTMLFromHash(bytes32 _hash) public view virtual returns (string memory) {
    return _tokenHTMLFromHash(_hash);
  }

  function tokenHTML(uint256 _tokenId) public view virtual returns (string memory) {
    return _tokenHTML(_tokenId);
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    string memory tokenImageUrl;
    {
      tokenImageUrl = string(abi.encodePacked(tokenImageURI, Strings.toString(_tokenId), '.png'));
    }

    string memory builtHTML = Base64.encode(bytes(_tokenHTML(_tokenId)));

    string memory json = Base64.encode(bytes(abi.encodePacked(
      '{"name": "', name ,' #', Strings.toString(_tokenId),'", "description": "', description, '", "image": "', tokenImageUrl, '", "attributes":[',
      _generateTraits(tokenHashes[_tokenId]),
      '], "animation_url": "data:text/html;base64,', builtHTML, '"}'
    )));
    return string(abi.encodePacked('data:application/json;base64,', json));
  }

  // implement in parent contract

  function _generateTraits(bytes32 _hash) internal pure virtual returns (string memory);
}
