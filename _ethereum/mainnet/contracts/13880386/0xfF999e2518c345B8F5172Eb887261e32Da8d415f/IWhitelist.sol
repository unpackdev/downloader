// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0 <0.9.0;

import "./IAuthenticator.sol";


/// @title IWhitelist 
/// @dev Whitelist authentication interface
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface IWhitelist is IAuthenticator {
    

    /// @dev Add `_accounts` to the whitelist
    /// @param _accounts The accounts to add
    function add(address[] calldata _accounts) external;


    /// @dev Remove `_accounts` from the whitelist
    /// @param _accounts The accounts to remove
    function remove(address[] calldata _accounts) external;
}