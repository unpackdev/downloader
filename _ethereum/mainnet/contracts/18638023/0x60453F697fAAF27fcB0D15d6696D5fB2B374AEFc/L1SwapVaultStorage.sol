// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "./IL1SwapVault.sol";

/// @title L1SwapVaultStorage
/// @dev Storage for the L1 swap vault contract
abstract contract L1SwapVaultStorage is IL1SwapVault {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The authorized keepers
    mapping(address => bool) public keepers;

    /// @notice The whitelisted contract addresses to trade on
    mapping(address => bool) public whitelisted;

    /// @notice The whitelisted recipients
    mapping(address => bool) public recipients;

    /// @notice The executed swaps
    mapping(bytes32 => bool) public executed;

    /// @notice Whether swap vault is dedicated to a particular address;
    bool public dedicated;

    /// @notice The whitelisted token addresses to swap from / into
    mapping(address => bool) public whitelistedToken;
}
