// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./IRewardsPool.sol";

contract RewardsPool is IRewardsPool, Ownable {
    IERC20 public stakedCredmark;
    IERC20 public credmark;

    uint256 public lastRewardTime;
    uint256 public endTime;

    bool public started;

    event PoolStarted(uint256 endTime);
    event EndTimeChanged(uint256 endTime);
    event RewardsIssued(uint256 amount);

    modifier hasStarted() {
        require(started, "Pool has not started");
        _;
    }

    constructor(IERC20 _credmark, IERC20 _stakedCredmark) {
        stakedCredmark = _stakedCredmark;
        credmark = _credmark;
    }

    function start(uint256 poolEndTime) external onlyOwner {
        require(!started, "Contract Already Started");
        require(poolEndTime > block.timestamp, "End time is not in future");

        lastRewardTime = block.timestamp;
        endTime = poolEndTime;
        started = true;

        emit PoolStarted(endTime);
    }

    function setEndTime(uint256 poolEndTime) external onlyOwner {
        require(poolEndTime > block.timestamp, "End time is not in future");

        if (endTime > 0) {
            issueRewards();
        }

        endTime = poolEndTime;

        emit EndTimeChanged(endTime);
    }

    function getLastRewardTime() external view override returns (uint256) {
        return lastRewardTime;
    }

    function issueRewards() public override hasStarted {
        uint256 rewardsAmount = unissuedRewards();

        lastRewardTime = block.timestamp;

        if (rewardsAmount > 0) {
            SafeERC20.safeTransfer(credmark, address(stakedCredmark), rewardsAmount);
            emit RewardsIssued(rewardsAmount);
        }
    }

    function unissuedRewards() public view override hasStarted returns (uint256) {
        if (endTime <= lastRewardTime) {
            return 0;
        }

        uint256 nowOrEndTime = block.timestamp;
        if (block.timestamp > endTime) {
            nowOrEndTime = endTime;
        }

        uint256 balance = credmark.balanceOf(address(this));
        uint256 rewardsAmount = (balance * (nowOrEndTime - lastRewardTime)) / (endTime - lastRewardTime);
        return rewardsAmount;
    }
}
