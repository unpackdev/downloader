// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.21;

import "./IGeyser.sol";

/**
 * @title IGeyserViewer
 * @notice Interface for the GeyserViewer contract
 */
interface IGeyserViewer {
    /**
     * @notice Batches some data queries for Geyser data
     * @dev Some of the data is dependent on the other data, meaning it cannot be parallelized by the frontend using a multicall.
     * @param geyser The address of the geyser to retrieve data for
     * @return geyserData The GeyserData that the Geyser provides directly
     * @return bonusTokens A list of any bonus tokens the Geyser has
     * @return rewardAmount The current reward token balance of the Geyser's RewardPool
     * @return bonusAmounts The current bonus token balances of the Geyser's RewardPool
     */
    function getData(address geyser)
        external
        view
        returns (
            IGeyser.GeyserData memory geyserData,
            address[] memory bonusTokens,
            uint256 rewardAmount,
            uint256[] memory bonusAmounts
        );

    /**
     * @notice Simulates an unstake and claim operation to compute a vault's current claim without modifying any chain state
     * @dev Some of the data is dependent on the other data, meaning it cannot be parallelized by the frontend using a multicall.
     * Typical state changes and error checks are omitted in this function and it should not be used for anything critical.
     * The intended use is solely as a way for frontend clients to quickly estimate a user's current position.
     * @param geyser The address of the geyser to retrieve data for
     * @param vault The address of the vault to handle
     * @param amount The amount being hypothetically unstaked
     * @return rewardShareNumerator The numerator of the reward share fraction
     * @return rewardShareDenominator The denominator of the reward share fraction
     */
    function previewUnstakeAndClaim(address geyser, address vault, uint256 amount)
        external
        view
        returns (uint256 rewardShareNumerator, uint256 rewardShareDenominator);
}
