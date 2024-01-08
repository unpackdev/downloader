// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.4;

interface IYearnRegistry {
    /// @notice Gets the vault to use for the specified token
    /// @param token The address of the token
    /// @return The address of the vault
    function latestVault(address token) external view returns (address);
}
