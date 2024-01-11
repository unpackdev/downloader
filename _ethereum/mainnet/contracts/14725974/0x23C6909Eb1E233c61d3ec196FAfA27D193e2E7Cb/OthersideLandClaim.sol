// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract OthersideLandClaim is ERC721A, Ownable {
  using Strings for uint256;
  
  string public revealURI = "https://ipfs.io/ipfs/QmUcxc6fHtRhUjxU7yKnexy2RhaVJxBoCAMfX4UeYQgh1w";
  uint256 public maxSupply = 100000;

  constructor() ERC721A("Otherside Land Claim", "OTHDLC") {}

  function Airdrop(address[] calldata recipients) external onlyOwner {
      uint256 startingSupply = totalSupply();
      require(startingSupply + recipients.length < maxSupply, "MAX_SUPPLY");
      for (uint256 i = 0; i < recipients.length; i++) {
        _safeMint(recipients[i], startingSupply + i);
      }
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "non_existant_token");
    return revealURI;
  }

  function setRevealUri(string memory _newRevealUri) public onlyOwner {
    revealURI = _newRevealUri;
  }
}