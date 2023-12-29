// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.21;

import "./IPoints.sol";
import "./IRageQuit.sol";
import "./IPointsVaultExtensionEvents.sol";
import "./IPointsVaultExtensionErrors.sol";

/**
 * @title IPointsVaultExtension
 * @notice Interface for the vault-extension of the Points contract.
 * @dev Does not support fee-on-transfer or rebasing tokens (in unwrapped form).
 */
interface IPointsVaultExtension is IPoints, IRageQuit, IPointsVaultExtensionEvents, IPointsVaultExtensionErrors {
    /**
     * @notice Get the length of the registered vaultFactory whitelist
     * @return length The length of the vaultFactory whitelist
     */
    function getVaultFactorySetLength() external view returns (uint256 length);

    /**
     * @notice Get the address of the vaultFactory at the corresponding index on the whitelist
     * @param index The index of the vaultFactory
     * @return factory The address of the vaultFactory at the index on the whitelist
     */
    function getVaultFactoryAtIndex(uint256 index) external view returns (address factory);

    /**
     * @notice Validate whether or not the target vault is from a whitelisted factory
     * @param vault The address of the vault in question
     * @return validity Whether the target vault is from a whitelisted factory or not
     */
    function isValidVault(address vault) external view returns (bool validity);

    /**
     * @notice Register a new vaultFactory onto the whitelist. Only callable by owner.
     * @param factory The address of the factory to add.
     */
    function registerVaultFactory(address factory) external;

    /**
     * @notice Remove a vaultFactory from the whitelist. Only callable by owner.
     * @param factory The address of the factory to remove.
     */
    function removeVaultFactory(address factory) external;

    /**
     * @notice Stake tokens from vault into Points contract.
     * @notice Vault must be from whitelisted vaultFactory.
     * @param vault Address of the vault to stake from.
     * @param token The address of the token.
     * @param amount The amount of tokens to deposit.
     * @param permission Permission signature from vault owner.
     */
    function stakeToken(address vault, address token, uint128 amount, bytes calldata permission) external;

    /**
     * @notice Unstake tokens from Points contract and transfer earned points to the vault.
     * @param vault Address of the vault to unstake from.
     * @param token The address of the token.
     * @param amount The amount of tokens to deposit.
     * @param permission Permission signature from vault owner.
     */
    function unstakeToken(address vault, address token, uint128 amount, bytes calldata permission) external;
}
