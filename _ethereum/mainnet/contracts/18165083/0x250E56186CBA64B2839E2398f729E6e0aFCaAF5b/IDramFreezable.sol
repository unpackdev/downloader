// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IDramFreezable {
    /**
     * @dev Happens when an account is in freezed state but the function requires a non-freezed account
     */
    error FreezedError();

    /**
     * @dev Happens when an account is in non-freezed state but the function requires a freezed account
     */
    error NotFreezedError();

    /**
     * @notice Gets emitted when `operator` freezes an `account`.
     * @param account freezed account
     * @param operator Address that freezed the account
     */
    event Freezed(address indexed account, address indexed operator);

    /**
     * @notice Gets emitted when `operator` un-freezes an `account`.
     * @param account Un-freezed account
     * @param operator Address that un-freezed the account
     */
    event Unfreezed(address indexed account, address indexed operator);

    /**
     * @notice Check if an account is in the freezed state.
     * @param account The account to be checked
     */
    function isFreezed(address account) external view returns (bool);
}
