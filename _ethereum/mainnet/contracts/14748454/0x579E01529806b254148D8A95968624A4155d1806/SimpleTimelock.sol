// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./SafeERC20.sol";

// solhint-disable not-rely-on-time
contract SimpleTimelock {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    uint256 public immutable lastLockTime;
    uint256 public immutable unlockTime;

    mapping(address => uint256) public lockedBalance;

    event Locked(address addr, uint256 amount);
    event Withdrawal(address addr, uint256 amount);

    constructor(IERC20 token_, uint256 lastLockTime_) {
        token = token_;
        lastLockTime = lastLockTime_;
        unlockTime = lastLockTime_ + (86400 * 90); // 90 days later
    }

    function lock(uint256 amount) external {
        require(block.timestamp <= lastLockTime, "SimpleTimelock: can no longer lock");
        lockedBalance[msg.sender] += amount;
        token.safeTransferFrom(msg.sender, address(this), amount);
        emit Locked(msg.sender, amount);
    }

    function withdraw() external {
        require(block.timestamp >= unlockTime, "SimpleTimelock: time not passed");
        uint256 balance = lockedBalance[msg.sender];
        require(balance > 0, "SimpleTimelock: nothing to withdraw");
        lockedBalance[msg.sender] = 0;
        token.safeTransfer(msg.sender, balance);
        emit Withdrawal(msg.sender, balance);
    }
}
