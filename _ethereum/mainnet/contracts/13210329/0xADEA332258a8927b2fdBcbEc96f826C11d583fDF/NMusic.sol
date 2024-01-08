// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./NPass.sol";

contract NMusic is NPass {

  string public myBaseURI;

  constructor()
    NPass(
      "N MUSIC",
      "NM",
      false,
      9999,
      8888,
      20000000000000000,
      30000000000000000
    )
  {}

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
    return super.tokenURI(tokenId);
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    myBaseURI = _newBaseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return myBaseURI;
  }

}
