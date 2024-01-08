// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./IOpenNFTs.sol";

contract OpenNFTs is ERC721, ERC721Enumerable, ERC721URIStorage, IOpenNFTs {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  constructor() ERC721("Open NFTs", "NFT") {}

  function mintNFT(address minter, string memory jsonURI)
    public
    override(IOpenNFTs)
    returns (uint256)
  {
    _tokenIds.increment();

    uint256 newItemId = _tokenIds.current();
    _safeMint(minter, newItemId);
    _setTokenURI(newItemId, jsonURI);

    return newItemId;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
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
    return interfaceId == type(IOpenNFTs).interfaceId || super.supportsInterface(interfaceId);
    // return super.supportsInterface(interfaceId);
  }
}
