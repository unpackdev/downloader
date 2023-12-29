// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "./IAuthenticator.sol";

/// @title IWhitelist 
/// @dev Whitelist authentication interface
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface IWhitelist is IAuthenticator {
    

    /// @dev Add `accounts` to the whitelist
    /// @param accounts The accounts to add
    function add(address[] memory accounts) external;


    /// @dev Remove `accounts` from the whitelist
    /// @param accounts The accounts to remove
    function remove(address[] memory accounts) external;
}