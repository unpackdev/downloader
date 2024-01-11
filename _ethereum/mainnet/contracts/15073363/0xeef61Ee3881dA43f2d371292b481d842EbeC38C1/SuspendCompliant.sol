// ----------------------------------------------------------------------------
// Copyright (c) 2022 BC Technology (Hong Kong) Limited
// https://bc.group
// See LICENSE file for license details.
// ----------------------------------------------------------------------------

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./AccessGuard.sol";

/// @title SuspendCompliant
/// @notice Suspend compliance module for the osl token
abstract contract SuspendCompliant is AccessGuard {
    /*==================== Events ====================*/

    event Suspend(address indexed operator, address indexed account);
    event Unsuspend(address indexed operator, address indexed account);
    event SuspendBatch(address indexed operator, address[] accounts);
    event UnsuspendBatch(address indexed operator, address[] accounts);

    /*==================== Global variables ====================*/

    /// @dev Mapping that will link addresses to booleans representing the
    /// suspended state of each address. The `True` value mapped to an address
    /// will represent that the address is suspended, and `False` that it is not.
    /// By default, no address is suspended.
    mapping(address => bool) private _suspended;

    /*==================== Public/external functions ====================*/

    /// @notice Check if a specific address is suspended or not
    /// @dev return true if the account is suspended and false if it is not
    /// @param account (address) address to check if suspended
    function isSuspended(address account) public view returns (bool) {
        return _suspended[account];
    }

    /// @notice Suspend an account
    /// @dev In order to suspend an account, the caller needs to be an operator. It will
    /// emit a `Suspend` event.
    /// @param account (address) Account to suspended
    function suspend(address account) external onlyRole(OPERATOR_ROLE) {
        _suspend(account);
    }

    /// @notice Unsuspend an account
    /// @dev In order to unsuspend an account, the caller needs to be an operator. It will
    /// emit an `Unsuspend` event.
    /// @param account (address) Account to unsuspend
    function unsuspend(address account) external onlyRole(OPERATOR_ROLE) {
        _unsuspend(account);
    }

    /// @notice Suspend a list of accounts
    /// @dev In order to suspend a list of accounts, the caller needs to be an operator.
    /// If any suspend action on an account reverts, the function will revert. It will emit an
    /// `Suspend` event for each account and at the end an `SuspendBatch` event having the whole list
    /// of accounts as an argument
    /// @param accounts (address[]) List of accounts to be suspended
    function suspendBatch(address[] calldata accounts)
        external
        onlyRole(OPERATOR_ROLE)
    {
        for (uint256 index = 0; index < accounts.length; index++) {
            _suspend(accounts[index]);
        }

        emit SuspendBatch(_msgSender(), accounts);
    }

    /// @notice Unsuspend a list of accounts
    /// @dev In order to unsuspend a list of accounts, the caller needs to be an operator.
    /// If any unsuspend action on an account reverts, the function will revert. It will emit an
    /// `Unsuspend` event for each account and at the end an `UnsuspendBatch` event having the whole list
    /// of accounts as an argument
    /// @param accounts (address[]) List of accounts to be unsuspend
    function unsuspendBatch(address[] calldata accounts)
        external
        onlyRole(OPERATOR_ROLE)
    {
        for (uint256 index = 0; index < accounts.length; index++) {
            _unsuspend(accounts[index]);
        }

        emit UnsuspendBatch(_msgSender(), accounts);
    }

    /*==================== Internal Functions ====================*/

    /// @notice Suspend an account
    /// @dev The address from the account argument will be flagged as suspended
    /// in the `_suspended` mapping. It will revert if the address is already suspended
    /// or if you try to suspend the zero address (address(0)). It will emit a `Suspend` event
    /// @param account (address) Address to be suspended
    function _suspend(address account) internal {
        require(
            !_suspended[account],
            "SuspendCompliant: Account is already suspended"
        );
        require(
            account != address(0),
            "SuspendCompliant: Cannot suspend zero address"
        );

        _suspended[account] = true;

        emit Suspend(_msgSender(), account);
    }

    /// @notice Unsuspend an account
    /// @dev The address from the account argument will be flagged as unsuspend
    /// in the `_suspended` mapping. It will revert if the address is not suspended.
    /// It will emit a `Suspend` event
    /// @param account (address) Address to be unsuspend
    function _unsuspend(address account) internal {
        require(
            _suspended[account],
            "SuspendCompliant: Account is not suspended"
        );

        _suspended[account] = false;

        emit Unsuspend(_msgSender(), account);
    }
}
