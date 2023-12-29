// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.21;

/**
 * @title IPointsEvents
 * @notice Interface for the Events emitted by the Points contract.
 */
interface IPointsEvents {
    /**
     * @notice Emitted when the paused status of the transfers is updated.
     * @param paused The new paused status
     */
    event IsPaused(bool paused);
    /**
     * @notice Emitted when the authorized burner is updated.
     * @param authorizedBurner The new authorized burner
     */
    event AuthorizedBurnerUpdated(address authorizedBurner);
    /**
     * @notice Emitted when the whitelist status of an account is updated.
     * @param account The account whose whitelist status was updated
     * @param whitelisted The new whitelist status
     */
    event WhitelistUpdated(address indexed account, bool whitelisted);
    /**
     * @notice Emitted when the rate of a token is updated.
     * @param token The token whose rate is updated
     * @param rate The new rate
     * @param timestamp The timestamp of the update
     */
    event RateUpdated(address indexed token, uint96 rate, uint32 timestamp);
    /**
     * @notice Emitted when points are converted to pending points.
     * @param account The account whose points were converted
     * @param token The staked token that earned the points
     * @param amount The amount of points converted
     */
    event PendingPointsConverted(address indexed account, address indexed token, uint256 amount);
    /**
     * @notice Emitted when multipliers are updated
     * @param token The token whose multipliers were updated
     * @param thresholds The new thresholds
     * @param scalars The new scalars
     */
    event MultipliersUpdated(address indexed token, uint128[] thresholds, uint128[] scalars);
}
