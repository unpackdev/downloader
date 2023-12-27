// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IConfigurable {
    /// @notice Updates the configuration for the calling contract.
    /// @param data The configuration data.
    function updateConfiguration(bytes calldata data) external;
}
