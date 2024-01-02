// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./console.sol";

// Error
error Connect__NotOwner();
error Connect__NotEnoughEth();

contract Connect {
  //state variables
  uint256 public constant MINIMUM_ETH = 5_000_000_000_000_00;
  address private immutable i_owner;

  // Modifiers
  modifier onlyOwner() {
    if (msg.sender != i_owner) revert Connect__NotOwner();
    _;
  }

  // Events
  event Funded(address indexed from, uint256 indexed amount);
  event Withdrawn(uint256 indexed amount);

  constructor() {
    i_owner = msg.sender;
  }

  function fund() public payable {
    if (msg.value < MINIMUM_ETH) revert Connect__NotEnoughEth();
    emit Funded(msg.sender, msg.value);
  }

  function withdraw() public payable onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
    emit Withdrawn(address(this).balance);
  }

  function getOwner() public view returns (address) {
    return i_owner;
  }

  fallback() external payable {
    fund();
  }

  receive() external payable {
    fund();
  }
}
