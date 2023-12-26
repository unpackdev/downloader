// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.21;

/**
 * @title IPointsVaultExtensionErrors
 * @notice Interface for the Errors emitted by the PointsVaultExtension contract.
 */
interface IPointsVaultExtensionErrors {
    /**
     * @notice Thrown when attempting to register a vaultFactory that has already been registered
     * @param vaultFactory The address of the vaultFactory that was already registered
     */
    error VaultFactoryAlreadyRegistered(address vaultFactory);
    /**
     * @notice Thrown when attempting to remove a vaultFactory that has not been registered
     * @param vaultFactory The address of the vaultFactory that was not already registered
     */
    error VaultFactoryNotRegistered(address vaultFactory);
    /**
     * @notice Thrown when attempting to stake with a vault that is not from a registered vaultFactory;
     * @param vault The address of the vault that was not from a registered vaultFactory
     */
    error InvalidVault(address vault);
}
