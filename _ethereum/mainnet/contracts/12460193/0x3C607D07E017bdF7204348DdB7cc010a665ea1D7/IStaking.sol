//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

// Libraries

// Contracts

// Interfaces

interface IStaking {
    function stake(uint256 pid, uint256 amountOrId) external;

    function unstake(uint256 pid, uint256 amountOrId) external;

    function addPool(
        uint256 allocationPoints,
        address token,
        bool withUpdate
    ) external;

    function pausePool(uint256 pid) external;

    function unpausePool(uint256 pid) external;

    function sweep(address token, uint256 amountOrId) external;

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() external;

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyUnstakeAll(uint256 pid) external;

    // Update the given pool's token allocation point. Can only be called by the owner.
    function setAllocPoint(
        uint256 pid,
        uint256 newAllocPoint,
        bool withUpdate
    ) external;

    function setOutputPerBlock(uint256 newOutputPerBlock) external;

    function setFeeReceiver(address newFeeReceiver) external;

    function setTokenValuator(address newTokenValuator) external;

    /* View Functions */

    function getTotalPools() external view returns (uint256);

    function getInfo()
        external
        view
        returns (
            uint256 totalPools,
            uint256 outputPerBlockNumber,
            uint256 startBlockNumber,
            uint256 bonusEndBlockNumber,
            bool bonusFinished,
            uint256 totalAllocPoints
        );

    function getUserInfoForPool(uint256 pid, address account)
        external
        view
        returns (
            uint256 amount,
            uint256 rewardDebt,
            uint256[] memory tokenIDs
        );

    function getPoolInfoFor(uint256 pid)
        external
        view
        returns (
            uint256 totalDeposit,
            address token,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accTokenPerShare,
            bool isPaused
        );

    // Return reward multiplier over the given fromBlock to toBlock block.
    function getMultiplier(uint256 fromBlock, uint256 toBlock) external view returns (uint256);

    function getPendingTokens(uint256 pid, address account) external view returns (uint256);

    function getAllPendingTokens(address account) external view returns (uint256);

    function getPools()
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory totalDeposit,
            uint256[] memory allocPoints,
            uint256[] memory lastRewardBlocks,
            uint256[] memory accTokenPerShares,
            bool[] memory isPaused,
            uint256 totalPools
        );

    /// @notice event emitted when a user has staked a token
    event Staked(address indexed user, uint256 pid, uint256 amount, uint256 valuedAmount);

    /// @notice event emitted when a user has unstaked a token
    event Unstaked(address indexed user, uint256 pid, uint256 amount, uint256 valuedAmount);

    /// @notice event emitted when a user claims reward
    event RewardPaid(address indexed user, uint256 pid, uint256 reward);

    /// @notice Emergency unstake tokens without rewards
    event EmergencyUnstake(address indexed user, uint256 pid);

    event OutputPerBlockUpdated(uint256 oldOutputPerBlock, uint256 newOutputPerBlock);

    event TokenValuatorUpdated(address indexed oldTokenValuator, address indexed newTokenValuator);

    event FeeReceiverUpdated(address indexed oldFeeReceiver, address indexed newFeeReceiver);

    event AllocPointsUpdated(uint256 pid, uint256 oldAllocPoints, uint256 newAllocPoints);

    event NewPoolAdded(
        address indexed token,
        uint256 pid,
        uint256 allocPoint,
        uint256 totalAllocPoint
    );

    event PoolPauseSet(uint256 pid, bool pause);

    event TokenSweeped(address indexed token, uint256 amountOrId);
}
