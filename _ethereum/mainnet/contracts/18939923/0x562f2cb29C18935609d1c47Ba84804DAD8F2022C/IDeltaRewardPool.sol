// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/**
 * @title IDeltaRewardPool
 * @dev IDeltaRewardPool interface
 * stakePool
 */
interface IDeltaRewardPool {
    function getUserStakeInfo(
        address user
    )
        external
        view
        returns (
            uint256 power,
            uint256 amount,
            uint256 stakeTime,
            uint256 stakeDuration
        );
}
