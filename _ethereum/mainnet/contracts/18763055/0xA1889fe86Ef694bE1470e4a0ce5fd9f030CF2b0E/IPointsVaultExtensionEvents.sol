// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.21;

/**
 * @title IPointsVaultExtensionEvents
 * @notice Interface for the Events emitted by the PointsVaultExtension contract.
 */
interface IPointsVaultExtensionEvents {
    /**
     * @notice Emitted when tokens are locked in a vault
     */
    event TokenVaultLocked(address indexed vault, address indexed token, uint256 amount);
    /**
     * @notice Emitted when tokens are unlocked from a vault
     */
    event TokenVaultUnlocked(address indexed vault, address indexed token, uint256 amount);
    /**
     * @notice Emitted when a vaultFactory is registered on the whitelist
     */
    event VaultFactoryRegistered(address indexed vaultFactory);
    /**
     * @notice Emitted when a vaultFactory is removed from the whitelist
     */
    event VaultFactoryRemoved(address indexed vaultFactory);
}
