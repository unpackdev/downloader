// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface FreezableInterface {

    /**
     * @dev Returns the frozen state of `account`.
     */
    function frozen(address account) external view returns (bool);

    /**
     * @dev Freezes activity of `account` until unfrozen
     */
    function freeze(address account)  external;

    /**
     * @dev Restores `account` activity
     */
    function unfreeze(address account) external;

}