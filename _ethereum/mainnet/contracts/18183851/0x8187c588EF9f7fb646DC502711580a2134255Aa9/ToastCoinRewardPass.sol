// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./Pausable.sol";
import "./ERC2981.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./DefaultOperatorFilterer.sol";

contract ToastCoinRewardPass is ERC721, ERC2981, Pausable, Ownable, DefaultOperatorFilterer {
  using Strings for uint256;

  uint256 public constant MAX_SUPPLY = 990;
  uint256 private _tokenCounter = 1;

  string public baseTokenURI;
  string public uriSuffix = ".json";

  constructor(string memory _name, string memory _symbol, string memory _baseTokenURI, address _royaltyReceiver, uint96 _defaultRoyaltyValue) ERC721(_name, _symbol) {
    baseTokenURI = _baseTokenURI;
    _setDefaultRoyalty(_royaltyReceiver, _defaultRoyaltyValue);
  }

  function adminMint(uint256 count, address receiver) external onlyOwner whenNotPaused {
    require(_tokenCounter + count <= MAX_SUPPLY + 1, "Cannot mint more than MAX_SUPPLY");
    for(uint256 i = 0; i < count; i++) {
      _safeMint(receiver, _tokenCounter);
      _tokenCounter += 1;
    }
  }

  function setRoyalty(address _newRoyaltyReceiver, uint96 _newRoyaltyValue) public onlyOwner {
    _setDefaultRoyalty(_newRoyaltyReceiver, _newRoyaltyValue);
  }

  function pause() public onlyOwner whenNotPaused {
    _pause();
  }

  function unpause() public onlyOwner whenPaused {
    _unpause();
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseTokenURI = _newBaseURI;
  }

  function setURISuffix(string memory _newURISuffix) public onlyOwner {
    uriSuffix = _newURISuffix;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    string memory currentBaseUri = _baseURI();
    return bytes(currentBaseUri).length > 0 ? string(abi.encodePacked(currentBaseUri, tokenId.toString(), uriSuffix)) : "";
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function setApprovalForAll(address operator, bool approved) public virtual override whenNotPaused onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve (address to, uint256 tokenId) public virtual override whenNotPaused onlyAllowedOperatorApproval(to) {
    super.approve(to, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public virtual override whenNotPaused onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override whenNotPaused onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override whenNotPaused onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
    return ERC721.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  }

  function totalSupply() public view returns (uint256) {
    return _tokenCounter - 1;
  }

}