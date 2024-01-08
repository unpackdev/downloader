// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";

abstract contract SwishBaseMasterchef {
    struct PoolData {
        IERC20Upgradeable rewardToken;
        uint256 accRewardPerShare; // Accumulated Rewards per share, times 1e36. See below.
        uint256 lastReward;
        uint256 curReward;
        uint256 pendingReward;
    }

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    uint256 public rewardPoolsCount;
    mapping(uint256 => PoolData) public rewardPools;
    mapping(uint256 => mapping(address => uint256)) internal userRewardDebt;
    mapping(uint256 => mapping(address => uint256)) internal userPendingRewards;

    function updateAccPerShare(uint256 pid, uint256 addedReward) internal {
        PoolData storage pool = rewardPools[pid];
        pool.curReward = pool.lastReward + addedReward;

        if (totalSupply == 0) {
            pool.accRewardPerShare = block.number;
            return;
        }

        pool.accRewardPerShare += (addedReward * (1e36)) / totalSupply;
    }

    function withdrawReward(uint256 pid, address user) internal {
        PoolData storage pool = rewardPools[pid];
        uint256 pending = ((balanceOf[user] * pool.accRewardPerShare) / 1e36) -
            userRewardDebt[pid][user];

        if (pending > 0) {
            userPendingRewards[pid][user] += pending;
            pool.pendingReward += pending;
        }

        pool.lastReward = pool.curReward - pending;
    }

    function harvest(uint256 pid, address user)
        internal
        returns (uint256 harvested)
    {
        harvested = userPendingRewards[pid][user];
        if (harvested > 0) {
            userPendingRewards[pid][user] = 0;
            rewardPools[pid].pendingReward -= harvested;
        }
    }

    function updateUserRewardDebt(uint256 pid, address user) internal {
        userRewardDebt[pid][user] =
            (balanceOf[user] * rewardPools[pid].accRewardPerShare) /
            1e36;
    }

    function pendingReward(
        uint256 pid,
        address user,
        uint256 addedReward
    ) internal view returns (uint256) {
        if (totalSupply == 0) return 0;

        uint256 newAccRewardPerShare = rewardPools[pid].accRewardPerShare +
            ((addedReward * 1e36) / totalSupply);

        return
            ((balanceOf[user] * newAccRewardPerShare) / 1e36) -
            userRewardDebt[pid][user] +
            userPendingRewards[pid][user];
    }
}
