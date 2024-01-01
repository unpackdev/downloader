// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "./FullMath.sol";
import "./Math.sol";

/// @title Math for computing rewards
/// @notice Allows computing rewards given some parameters of stakes and incentives
library RewardMath {
    /// @notice Compute the amount of rewards owed given parameters of the incentive and stake
    /// @param startTime When the incentive rewards began in epoch seconds
    /// @param liquidity The amount of liquidity, assumed to be constant over the period over which the snapshots are measured
    /// @param secondsPerLiquidityInsideInitialX128 The seconds per liquidity of the liquidity tick range as of the beginning of the period
    /// @param secondsPerLiquidityInsideX128 The seconds per liquidity of the liquidity tick range as of the current block timestamp
    /// @param currentTime The current block timestamp, which must be greater than or equal to the start time
    ///// @param rewardMultiplier The reward multiplier
    /// @return reward The amount of rewards owed
    /// @return secondsInsideX128 The total liquidity seconds inside the position's range for the duration of the stake
    function computeRewardAmount(
        uint256 startTime,
        uint128 liquidity,
        uint160 secondsPerLiquidityInsideInitialX128,
        uint160 secondsPerLiquidityInsideX128,
        uint256 currentTime,
        uint256 rewardMultiplier
    ) internal pure returns (uint256 reward, uint160 secondsInsideX128) {
        // this should never be called before the start time
        assert(currentTime >= startTime);

        // this operation is safe, as the difference cannot be greater than 1/stake.liquidity
        secondsInsideX128 = (secondsPerLiquidityInsideX128 - secondsPerLiquidityInsideInitialX128) * liquidity;

        reward = secondsInsideX128 * rewardMultiplier;
    }
}