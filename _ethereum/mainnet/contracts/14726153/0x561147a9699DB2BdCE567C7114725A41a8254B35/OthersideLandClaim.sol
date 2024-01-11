// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract OtherdeedKeys is ERC721A, Ownable {
  using Strings for uint256;
  
  string public revealURI = "https://ipfs.io/ipfs/QmUcxc6fHtRhUjxU7yKnexy2RhaVJxBoCAMfX4UeYQgh1w";
  uint256 public maxSupply = 100000;

  constructor() ERC721A("Otherdeed Keys", "OTHDK") {}

  function airdrop(address[] memory _users) external onlyOwner {
    for (uint256 i = 0; i < _users.length; i++) {
        _safeMint(_users[i], 1);
    }
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "non_existant_token");
    return revealURI;
  }
}