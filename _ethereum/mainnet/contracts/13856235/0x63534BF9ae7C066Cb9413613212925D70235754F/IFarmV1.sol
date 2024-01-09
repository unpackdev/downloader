//SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

interface IUnipilotFarmV1 {
    struct PoolInfo {
        uint256 startBlock;
        uint256 globalReward;
        uint256 lastRewardBlock;
        uint256 totalLockedLiquidity;
        uint256 rewardMultiplier;
        bool isRewardActive;
        bool isAltActive;
    }
    function poolInfo(address pool) external view returns (PoolInfo memory);
}
