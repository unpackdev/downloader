// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "./IERC20.sol";

contract EthStaking {
  IERC20 public stakingToken;

  mapping(address => uint256) public balanceOf;

  uint256 public totalSupply;

  event Deposit(address account, uint256 amount);

  event Withdraw(address account, uint256 amount);

  constructor(address _stakingToken) {
    stakingToken = IERC20(_stakingToken);
  }

  function deposit(uint256 amount) external {
    stakingToken.transferFrom(msg.sender, address(this), amount);
    balanceOf[msg.sender] += amount;
    totalSupply += amount;

    emit Deposit(msg.sender, amount);
  }

  function withdraw(uint256 amount) external {
    balanceOf[msg.sender] -= amount;
    totalSupply -= amount;
    stakingToken.transfer(msg.sender, amount);

    emit Withdraw(msg.sender, amount);
  }
}
