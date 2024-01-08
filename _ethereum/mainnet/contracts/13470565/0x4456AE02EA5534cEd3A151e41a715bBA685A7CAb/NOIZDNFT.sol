pragma solidity 0.8.4;

// SPDX-License-Identifier: UNLICENSED

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract NOIZDNFT is ERC721, ERC721URIStorage, Ownable, ERC721Enumerable
{
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIdCounter;
  mapping (uint256 => string) private _tokenURIs;

  constructor() ERC721("NOIZDNFT", "NDN") {}

  /**
    Set the base URI that will be used for storage.
  */
  function _baseURI()
    internal
    pure
    override
    returns (string memory)
  {
    return "ipfs://";
  }

  /**
    Safely mint the NFT.

    to          The address of the owner of the NFT.
    tokenURI    The URI identifying the IPFS JSON file.
  */
  function safeMint(address to, string memory _tokenURI)
    public
    onlyOwner
    returns (uint256)
  {
    uint256 tokenId = _tokenIdCounter.current();
    _safeMint(to, tokenId);
    _tokenURIs[tokenId] = _tokenURI;
    _tokenIdCounter.increment();
    return tokenId;
  }

  /**
    Override the method from ERC721 to use _tokenURIs[tokenId]
    instead of tokenId.
  */
  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenURIs[tokenId])) : "";
  }

  // The following functions are overrides required by Solidity.

  function _burn(uint256 tokenId)
    internal
    override(ERC721, ERC721URIStorage)
  {
    super._burn(tokenId);
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
      internal
      override(ERC721, ERC721Enumerable)
  {
      super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
      return super.supportsInterface(interfaceId);
  }
}
