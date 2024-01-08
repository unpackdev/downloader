// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";

contract FriendsOfLoomlock is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable {
  using Counters for Counters.Counter;

  string private _tokenBaseURI;
  bool private _tokenBaseURILocked;
  Counters.Counter private _tokenIdCounter;
  mapping (uint256 => string) private _tokenURIPaths;
  string private _contractURI;

  constructor(
    string memory tokenName_,
    string memory tokenSymbol_,
    string memory tokenBaseURI_,
    string memory contractURI_
  )
  ERC721(tokenName_, tokenSymbol_) {
    _tokenBaseURI = tokenBaseURI_;
    _contractURI = contractURI_;
  }

  function setTokenBaseURI(string calldata tokenBaseURI_) public onlyOwner {
    require(!_tokenBaseURILocked, "Token base URI is locked");
    _tokenBaseURI = tokenBaseURI_;
  }

  function lockTokenBaseURI() public onlyOwner {
    require(!_tokenBaseURILocked, "Token base URI is locked");
    _tokenBaseURILocked = true;
  }

  function tokenBaseURILocked() public view returns (bool) {
    return _tokenBaseURILocked;
  }

  function mintedSupply() public view returns (uint256) {
    return _tokenIdCounter.current();
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function mint(address to_, string calldata arweaveURIPath_) public onlyOwner whenNotPaused {
    require(bytes(arweaveURIPath_).length > 0, "Missing arweave URI path");
    _safeMint(to_, mintedSupply());
    _tokenURIPaths[mintedSupply()] = arweaveURIPath_;
    _tokenIdCounter.increment();
  }

  function mintBatch(address[] calldata addresses_, string[] calldata arweaveURIPaths_) public onlyOwner whenNotPaused {
    require(addresses_.length == arweaveURIPaths_.length, "Addresses & quantites not equal length");
    for (uint256 i = 0; i < addresses_.length; i++) {
      mint(addresses_[i], arweaveURIPaths_[i]);
    }
  }

  function addressHoldings(address addr_) external view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(addr_);
    uint256[] memory tokens = new uint256[](tokenCount);
    for (uint256 i = 0; i < tokenCount; i++) {
      tokens[i] = tokenOfOwnerByIndex(addr_, i);
    }
    return tokens;
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal whenNotPaused override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function _baseURI() internal view override returns (string memory) {
    return _tokenBaseURI;
  }

  // Contract-level metadata for OpenSea.
  function setContractURI(string calldata contractURI_) public onlyOwner {
    _contractURI = contractURI_;
  }

  // Contract-level metadata for OpenSea.
  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  // The following functions are overrides required by Solidity.

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenURIPaths[tokenId])) : "";
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}
