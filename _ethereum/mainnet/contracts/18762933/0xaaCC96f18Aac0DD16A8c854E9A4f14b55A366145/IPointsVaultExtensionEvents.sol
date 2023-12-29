// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.21;

/**
 * @title IPointsVaultExtensionEvents
 * @notice Interface for the Events emitted by the PointsVaultExtension contract.
 */
interface IPointsVaultExtensionEvents {
    /**
     * @notice Emitted when tokens are locked in a vault
     * @param vault The address of the vault that tokens were locked in
     * @param token The address of the token that was locked in the vault
     * @param amount The amount of tokens that were locked in the vault
     */
    event TokenVaultLocked(address indexed vault, address indexed token, uint256 amount);
    /**
     * @notice Emitted when tokens are unlocked from a vault
     * @param vault The address of the vault that tokens were unlocked from
     * @param token The address of the token that was unlocked from the vault
     * @param amount The amount of tokens that were unlocked from the vault
     */
    event TokenVaultUnlocked(address indexed vault, address indexed token, uint256 amount);
    /**
     * @notice Emitted when a vaultFactory is registered on the whitelist
     * @param vaultFactory The address of the vaultFactory was registered
     */
    event VaultFactoryRegistered(address indexed vaultFactory);
    /**
     * @notice Emitted when a vaultFactory is removed from the whitelist
     * @param vaultFactory The address of the vaultFactory that was removed
     */
    event VaultFactoryRemoved(address indexed vaultFactory);
}
