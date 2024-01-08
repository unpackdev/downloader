// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721Enumerable.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

import "./TokenStandardBase.sol";

// each token has a URI string that can be updated by the owner
// the URI can be data: url's for onchain metadata
contract TokenUriBase is TokenStandardBase {

  mapping(uint256 => string) private _tokenURIs;

  constructor (
    string memory name_,
    string memory symbol_,
    address openseaProxyRegistryAddress_,
    address payable royaltyAddress_,
    uint256 royaltyBps_
  ) TokenStandardBase(name_, symbol_, openseaProxyRegistryAddress_, royaltyAddress_, royaltyBps_) {
    
  }

  // TOKEN URI
  function tokenURI(
    uint256 tokenId
  ) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return _tokenURIs[tokenId];
  }

  // the owner (or approved) for a token should be able to update the URI
  // for whatever reason - if they can burn the token then they should be able to update the URI
  function updateTokenURI(
    uint256 tokenId,
    string calldata uri
  ) public virtual {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Metadata: caller is not owner nor approved");
    require(bytes(uri).length > 0, "ERC721Metadata: no URI set for token");
    _tokenURIs[tokenId] = uri;
  }

  //
  //
  // TOKEN MINT / BURN
  //
  //
  function mint(
    address,
    uint256
  ) public virtual override onlyOwner onlyUnsealed {
    require(false, "ERC721Metadata: must use the mintWithUri to mint");
  }

  function mintWithUri(
    address to,
    uint256 tokenId,
    string calldata uri
  ) public virtual onlyOwner onlyUnsealed {
    require(bytes(uri).length > 0, "ERC721Metadata: no URI set for token");
    _safeMint(to, tokenId);
    _tokenURIs[tokenId] = uri;
  }

  function _burn(
    uint256 tokenId
  ) internal virtual override {
    super._burn(tokenId);
    if (bytes(_tokenURIs[tokenId]).length != 0) {
      delete _tokenURIs[tokenId];
    }
  }

}
