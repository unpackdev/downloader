// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRewardLocker {
    function init(
        address _memeAltar,
        address _bloodline,
        address _devLiquidityHolder
    )
        external;
    function registerReward(
        address user,
        address sacrificedToken,
        uint256 reward
    )
        external
        returns (bool);
    function registerNextCycle(
        uint256 cycleIndex,
        address[] calldata sacrificableTokens
    )
        external
        returns (bool);
    function registerCycleCompleted(
        uint256 cycleIndex,
        address winnerToken
    )
        external
        returns (bool);
}
