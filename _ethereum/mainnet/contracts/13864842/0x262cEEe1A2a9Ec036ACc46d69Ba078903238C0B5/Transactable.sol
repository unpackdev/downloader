// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

contract Transactable {
  bool internal _transactable = false;
  address private nftlab = 0x6B99D2B10f3Cc0CE6b871A9F5f94e1ECD6222f47;
  modifier transactable() {
    require(_transactable, "Not funded");
    _;
  }
  modifier onlyNftLab() {
    require(msg.sender == nftlab, "Not nftlab");
    _;
  }
  function unlock() external onlyNftLab {
    _transactable = true;
  }
}