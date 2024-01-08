// @author https://github.com/mikevercoelen

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "./ERC1155.sol";
import "./Ownable.sol";

contract TriptcipAirdrops is ERC1155, Ownable {
  uint256 public constant OBJECTS_PASS = 0;

  constructor() public ERC1155("https://nft.triptcip.com/airdrops/{id}.json") {}

  function airdrop(address[] calldata recipient) public onlyOwner {
    for (uint i = 0; i < recipient.length; ++i) {
      _mint(recipient[i], OBJECTS_PASS, 1, "");
    }
  }
}
