// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";

contract GoldenBone is ERC721, Ownable {
  string bURI;

  constructor(string memory _uri) ERC721("Golden Bone", "JGB") {
    bURI = _uri;
  }

  function _baseURI() internal view override returns (string memory) {
    return bURI;
  }

  function mint(address _to, uint256 tokenId) public onlyOwner {
    _mint(_to, tokenId);
  }

  function setURI(string calldata _uri) public onlyOwner {
    bURI = _uri;
  }
}