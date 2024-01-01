// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ERC1155.sol";

abstract contract ERC1155URIStorage is ERC1155 {
  mapping(uint256 tokenId => string tokenUri) private _tokenURIs;

  function uri(uint256 tokenId) public view virtual override returns (string memory) {
    return _tokenURIs[tokenId];
  }

  function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
    _tokenURIs[tokenId] = _tokenURI;
  }
}
