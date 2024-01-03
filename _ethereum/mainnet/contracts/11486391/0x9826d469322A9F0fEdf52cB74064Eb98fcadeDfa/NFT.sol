// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;

import "./ERC1155.sol";

contract NFT is ERC1155 {
  uint256 public constant VISIONARY = 0;
  uint256 public constant EXPLORER = 1;
  uint256 public constant ALCHEMIST = 2;
  uint256 public constant VOYAGER = 3;
  uint256 public constant LEGEND = 4;
  uint256 public constant SUPREME = 5;
  uint256 public constant IMMORTAL = 6;
  uint256 public constant DIVINITY = 7;

  constructor(string memory uri) public ERC1155(uri) {
    _mint(msg.sender, VISIONARY, 10, '');
    _mint(msg.sender, EXPLORER, 8, '');
    _mint(msg.sender, ALCHEMIST, 6, '');
    _mint(msg.sender, VOYAGER, 5, '');
    _mint(msg.sender, LEGEND, 4, '');
    _mint(msg.sender, SUPREME, 2, '');
    _mint(msg.sender, IMMORTAL, 1, '');
    _mint(msg.sender, DIVINITY, 1, '');
  }
}
