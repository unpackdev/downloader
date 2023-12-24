// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

/// @title IAuthenticator
/// @dev Authenticator interface
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface IAuthenticator {
    
    /// @dev Authenticate 
    /// Returns whether `account` is authenticated
    /// @param account The account to authenticate
    /// @return whether `account` is successfully authenticated
    function authenticate(address account) external view returns (bool);
}