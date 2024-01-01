// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";

contract IceLock is Ownable {
  constructor(address _ice) {
    iceToken = ERC20(_ice);
  }

  ERC20 public iceToken;
  mapping(address => uint256) public balances;

  function lock(uint256 amount) external {
    require(amount > 0, "Amount must be greater than 0");
    require(iceToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
    balances[msg.sender] += amount;
  }

  function unlock() external {
    uint256 amount = balances[msg.sender];
    balances[msg.sender] = 0;
    require(iceToken.transfer(msg.sender, amount), "Transfer failed");
  }

  function withdraw() external onlyOwner {
    uint256 amount = iceToken.balanceOf(address(this));
    require(iceToken.transfer(msg.sender, amount), "Transfer failed");
  }
}
