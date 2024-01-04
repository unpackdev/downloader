// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IScheduler.sol";
import "./IERC20.sol";
import "./WSBTimeLockLib.sol";
import "./console.sol";

contract WSBTimeLock {
  using WSBTimeLockLib for *;
  uint256 public counter;
  mapping (uint256 => WSBTimeLockLib.TimeLock) public locks;
  IERC20 public wsb;
  IScheduler public scheduler;
  address public whitelisted;
  uint256 lockDelay;
  constructor(address _wsb, address _whitelisted, uint256 _lockDelay) public {
    whitelisted = _whitelisted;
    wsb = IERC20(_wsb);
    lockDelay = _lockDelay;
  }
  modifier onlyWhitelisted {
    require(msg.sender == whitelisted, "only whitelisted address");
    _;
  }
  function deposit(uint256 amount) public onlyWhitelisted {
    require(wsb.transferFrom(msg.sender, address(this), amount), "failed to transferFrom");
  }
  event ScheduledCallback(uint256 indexed number);
  function withdraw(uint256 amount) public onlyWhitelisted {
    uint256 _counter = counter;
    uint256 release = block.timestamp + lockDelay;
    locks[_counter].release = release;
    locks[_counter].amount = amount;
    counter++;
    emit ScheduledCallback(_counter);
  }
  function withdrawCallback(uint256 counterValue) public {
    WSBTimeLockLib.TimeLock storage lock = locks[counterValue];
    require(lock.getState() == WSBTimeLockLib.TimeLockState.INITIALIZED, "lock already resolved or never initialized");
    require(lock.release <= block.timestamp, "not enough time elapsed to release locked funds");
    lock.markDone();
    require(wsb.transfer(whitelisted, lock.amount), "failed to transfer");
  }
}

