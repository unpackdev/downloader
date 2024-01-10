// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";

contract GamerPlaques is Ownable, ERC721 {
  string private _baseTokenURI;

  constructor(string memory baseURI) ERC721("Gamer Plaques", "GPLAQUE") {
    _baseTokenURI = baseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function award(address gamer, uint tokenId) external onlyOwner {
    _safeMint(gamer, tokenId);
  }
}