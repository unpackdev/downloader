// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.21;

/**
 * @title IPointsEvents
 * @notice Interface for the Events emitted by the Points contract.
 */
interface IPointsEvents {
    /**
     * @notice Emitted when the paused status of the transfers is updated.
     */
    event IsPaused(bool paused);
    /**
     * @notice Emitted when the whitelist status of an account is updated.
     */
    event WhitelistUpdated(address indexed account, bool whitelisted);
    /**
     * @notice Emitted when the rate of a token is updated.
     */
    event RateUpdated(address indexed token, uint96 rate, uint32 timestamp);
    /**
     * @notice Emitted when points are converted to pending points.
     */
    event PendingPointsConverted(address indexed account, address indexed token, uint256 amount);
    /**
     * @notice Emitted when tokens are deposited.
     */
    event TokenDeposited(address indexed account, address indexed token, uint256 amount);
    /**
     * @notice Emitted when tokens are withdrawn.
     */
    event TokenWithdrawn(address indexed account, address indexed token, uint256 amount);
    /**
     * @notice Emitted when multipliers are updated
     */
    event MultipliersUpdated(address indexed token, uint128[] thresholds, uint128[] scalars);
}
