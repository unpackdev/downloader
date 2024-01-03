pragma solidity ^0.6.2;

import "./ERC1155.sol";


// NFT Gradient token
// Stores two values for every token: outer color and inner color
contract OctopusNFT is ERC1155 {
  uint256 public constant GOLD = 0;
  uint256 public constant SILVER = 1;
  uint256 public constant BRONZE = 2;

  constructor() public ERC1155("https://bot.octopuscc.io/api/tokens1155/{id}.json") {
    _mint(msg.sender, GOLD, 2000, "");
    _mint(msg.sender, SILVER, 5000, "");
    _mint(msg.sender, BRONZE, 10000, "");
  }
}

