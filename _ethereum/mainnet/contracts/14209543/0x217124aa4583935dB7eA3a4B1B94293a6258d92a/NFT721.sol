// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract NFT721 is ERC721Enumerable, ERC721URIStorage, Ownable {

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  constructor() ERC721("BBRZ", "BBRZ") {
    _setOwner(msg.sender);
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
      internal
      override(ERC721, ERC721Enumerable)
  {
      super._beforeTokenTransfer(from, to, tokenId);
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
      super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId)
      public
      view
      override(ERC721, ERC721URIStorage)
      returns (string memory)
  {
      return super.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
      public
      view
      override(ERC721, ERC721Enumerable)
      returns (bool)
  {
      return super.supportsInterface(interfaceId);
  }

  function mintNft(address receiver, string memory tokenURI) public returns (uint256) {
    _tokenIds.increment();

    uint256 newNftTokenId = _tokenIds.current();
    _mint(receiver, newNftTokenId);
    _setTokenURI(newNftTokenId, tokenURI);

    return newNftTokenId;
  }

  function burnNft(uint256 tokenId) external onlyOwner {
    _burn(tokenId);
  }

  function updateTokenURI(uint256 tokenId, string memory tokenURI) external onlyOwner {
    _setTokenURI(tokenId, tokenURI);
  }
}