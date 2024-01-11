// ----------------------------------------------------------------------------
// Copyright (c) 2022 BC Technology (Hong Kong) Limited
// https://bc.group
// See LICENSE file for license details.
// ----------------------------------------------------------------------------

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./AccessGuard.sol";

/// @title WhitelistCompliant
/// @notice Whitelist compliance module for the osl token
abstract contract WhitelistCompliant is AccessGuard {
    /*==================== Events ====================*/

    event Whitelist(address indexed operator, address indexed account);
    event RemoveWhitelist(address indexed operator, address indexed account);
    event WhitelistBatch(address indexed operator, address[] accounts);
    event RemoveWhitelistBatch(address indexed operator, address[] accounts);

    /*==================== Global variables ====================*/

    /// @dev Mapping that will link addresses to booleans representing the
    /// whitelist state of each address. The `True` value mapped to an address
    /// will represent that the address is whitelisted, and `False` that it is not.
    /// By default, no address is whitelisted.
    mapping(address => bool) private _whitelisted;

    /*==================== Public/external functions ====================*/

    /// @notice Check if a specific address is whitelisted or not
    /// @dev return true if the account is whitelisted and false if it is not
    /// @param account (address) address to check if whitelisted
    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisted[account];
    }

    /// @notice Whitelist an account
    /// @dev In order to whitelist an account, the caller needs to be an operator. It will
    /// emit a `Whitelist` event.
    /// @param account (address) Account to whitelist
    function whitelist(address account) external onlyRole(OPERATOR_ROLE) {
        _whitelist(account);
    }

    /// @notice Remove an account from whitelist
    /// @dev In order to remove an account from the whitelist, the caller needs to be an operator. It will
    /// emit a `RemoveWhitelist` event.
    /// @param account (address) Account to be removed from the whitelist
    function removeWhitelist(address account) external onlyRole(OPERATOR_ROLE) {
        _removeWhitelist(account);
    }

    /// @notice Whitelist a list of accounts
    /// @dev In order to whitelist a list of accounts, the caller needs to be an operator.
    /// If any whitelist action on an account reverts, the function will revert. It will emit an
    /// `Whitelist` event for each account and at the end an `WhitelistBatch` event having the whole list
    /// of accounts as an argument
    /// @param accounts (address[]) List of accounts to be whitelisted
    function whitelistBatch(address[] calldata accounts)
        external
        onlyRole(OPERATOR_ROLE)
    {
        for (uint256 index = 0; index < accounts.length; index++) {
            _whitelist(accounts[index]);
        }

        emit WhitelistBatch(_msgSender(), accounts);
    }

    /// @notice Remove a list of accounts from the whitelist
    /// @dev In order to remove a list of accounts from the whitelist, the caller needs to be an operator.
    /// If any removal action on any account reverts, the function will revert. It will emit an
    /// `RemoveWhitelist` event for each account and at the end an `RemoveWhitelistBatch` event having the whole list
    /// of accounts as an argument
    /// @param accounts (address[]) List of accounts to be whitelisted
    function removeWhitelistBatch(address[] calldata accounts)
        external
        onlyRole(OPERATOR_ROLE)
    {
        for (uint256 index = 0; index < accounts.length; index++) {
            _removeWhitelist(accounts[index]);
        }

        emit RemoveWhitelistBatch(_msgSender(), accounts);
    }

    /*==================== Internal Functions ====================*/

    /// @notice Whitelist an account
    /// @dev The address from the account argument will be flagged as whitelisted
    /// in the `_whitelisted` mapping. It will revert if the address is already Whitelisted
    /// or if you try to whitelist the zero address (address(0)). It will emit a `Whitelist` event
    /// @param account (address) Address to pe suspended
    function _whitelist(address account) internal {
        require(
            !_whitelisted[account],
            "WhitelistComplaint: Account is already whitelisted"
        );
        require(
            account != address(0),
            "WhitelistComplaint: Cannot whitelist zero address"
        );

        _whitelisted[account] = true;

        emit Whitelist(_msgSender(), account);
    }

    /// @notice Remove an account from whitelist
    /// @dev The address from the account argument will be flagged as not whitelisted
    /// in the `_whitelisted` mapping. It will revert if the address is not on the whitelist.
    /// It will emit a `RemoveWhitelist` event.
    /// @param account (address) Address to pe suspended
    function _removeWhitelist(address account) internal {
        require(
            _whitelisted[account],
            "WhitelistComplaint: Account is not whitelisted"
        );

        _whitelisted[account] = false;

        emit RemoveWhitelist(_msgSender(), account);
    }
}
