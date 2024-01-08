// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;
pragma abicoder v2;

import "./IERC20.sol";

import "./ILiquidityMining.sol";
import "./IERC20Metadata.sol";

contract LiquidityMiningView {

    struct PoolInfo {
        uint256 pid;
        address token;
        uint8 decimals;
        uint256 totalStaked;
        uint256 accRewardPerShare;
        uint256 allocPoint;
        uint256 lastRewardBlock;

    }

    struct LiquidityMining {
        address rewardToken;
        uint8 rewardTokenDecimals;
        address reservoir;
        uint256 rewardPerBlock;
        uint256 startBlock;
        uint256 endBlock;
        uint256 currentBlock;
        uint256 currentTimestamp;
        PoolInfo[] pools;
        ILiquidityMining.UnlockInfo[] unlocks;
    }

    function getLiquidityMiningInfo(address _liquidityMining)
    external view
    returns (
        LiquidityMining memory liquidityMiningData
    )
    {
        ILiquidityMining liquidityMining = ILiquidityMining(_liquidityMining);

        ILiquidityMining.PoolInfo[] memory poolInfos = liquidityMining.getAllPools();
        PoolInfo[] memory pools = new PoolInfo[](poolInfos.length);
        uint256 i;
        for(i = 0; i < poolInfos.length; i++) {
            ILiquidityMining.PoolInfo memory pi = poolInfos[i];
            PoolInfo memory info = PoolInfo(
                i,
                pi.token,
                IERC20Metadata(pi.token).decimals(),
                IERC20(pi.token).balanceOf(_liquidityMining),
                pi.accRewardPerShare,
                pi.allocPoint,
                pi.lastRewardBlock
            );
            pools[i] = info;
        }

        liquidityMiningData = LiquidityMining(
            liquidityMining.rewardToken(),
            IERC20Metadata(liquidityMining.rewardToken()).decimals(),
            liquidityMining.reservoir(),
            liquidityMining.rewardPerBlock(),
            liquidityMining.startBlock(),
            liquidityMining.endBlock(),
            block.number,
            block.timestamp,
            pools,
            liquidityMining.getAllUnlocks()
        );
    }

    struct UserCommonRewardInfo {
        uint256 reward;
        uint256 claimedReward;
        uint256 unlockedReward;
        uint8 rewardTokenDecimals;
    }

    struct UserPoolRewardInfo {
        uint256 pid;
        address poolToken;
        uint8   poolTokenDecimals;
        uint256 unlockedReward;
        uint256 totalReward;
        uint256 staked;
        uint256 balance;
    }

    function getUserRewardInfos(address _liquidityMining, address _staker)
    external view
    returns (
        UserCommonRewardInfo memory userCommonRewardInfo,
        UserPoolRewardInfo[] memory userPoolRewardInfos
    )
    {
        ILiquidityMining liquidityMining = ILiquidityMining(_liquidityMining);

        userCommonRewardInfo = UserCommonRewardInfo(
            liquidityMining.rewards(_staker),
            liquidityMining.claimedRewards(_staker),
            liquidityMining.calcUnlocked(liquidityMining.rewards(_staker)),
            IERC20Metadata(liquidityMining.rewardToken()).decimals()
        );

        ILiquidityMining.PoolInfo[] memory pools = liquidityMining.getAllPools();
        userPoolRewardInfos = new UserPoolRewardInfo[](pools.length);
        uint256 i;
        for(i = 0; i < pools.length; i++) {
            uint256 pid = liquidityMining.poolPidByAddress(pools[i].token);
            (uint256 total, uint256 unlocked) = liquidityMining.getPendingReward(pid, _staker);

            UserPoolRewardInfo memory info = UserPoolRewardInfo(
                pid,
                pools[i].token,
                IERC20Metadata(pools[i].token).decimals(),
                unlocked,
                total,
                liquidityMining.userPoolInfo(pid, _staker).amount,
                IERC20(pools[i].token).balanceOf(msg.sender)
            );
            userPoolRewardInfos[i] = info;
        }
    }
}
