// SPDX-License-Identifier: Private
pragma solidity ^0.8.20;

interface IFreezable {
    /**
     * @dev Indicates an error when freezed address called function
     * @param account Address who calls
     */
    error EnforcedFreeze(address account);

    /**
     * @dev The operation failed because the address is not freezed.
     */
    error ExpectedFreeze(address account);

    /**
     * @dev Emitted when the freeze is triggered by `account`.
     */
    event Freezed(address indexed account);

    /**
     * @dev Emitted when the freeze is lifted by `account`.
     */
    event Unfreezed(address indexed account);

    /**
     * @dev Returns true if the address is freezed, and false otherwise.
     *
     * Requirements:
     *
     *  @param target The verified address
     */
    function freezed(address target) external view returns (bool);

    function freeze(address target) external;

    function unfreeze(address target) external;
}
