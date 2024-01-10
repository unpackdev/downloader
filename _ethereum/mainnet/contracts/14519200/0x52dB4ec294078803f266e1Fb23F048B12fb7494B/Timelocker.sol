// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Timelocker {
  struct Locker {
    uint256 releaseTime;
    uint256 amount;
    bool released;
  }
  ERC20 public immutable token;
  mapping(address => Locker[]) public lockers;

  constructor(address tokenAddress) {
    token = ERC20(tokenAddress);
  }

  function deposit(
    address recipent,
    uint256 releaseTime,
    uint256 amount
  ) public {
    token.transferFrom(msg.sender, address(this), amount);
    Locker memory newLocker = Locker({
      releaseTime: releaseTime,
      amount: amount,
      released: false
    });
    lockers[recipent].push(newLocker);
  }

  function deposits(
    address[] memory recipents,
    uint256 releaseTime,
    uint256 amount
  ) external {
    for (uint256 i = 0; i < recipents.length; i++) {
      deposit(recipents[i], releaseTime, amount);
    }
  }

  function release(uint256 lockerId) external {
    require(lockers[msg.sender].length >= lockerId);
    require(lockers[msg.sender][lockerId].releaseTime <= block.timestamp);
    require(lockers[msg.sender][lockerId].released == false);
    token.transfer(msg.sender, lockers[msg.sender][lockerId].amount);
    lockers[msg.sender][lockerId].released = true;
  }
}
