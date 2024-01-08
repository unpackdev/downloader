// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an sunset
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenSun` and `whenMoon`, which can be applied to
 * the functions of your contract. Note that they will not be useable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Sunsetable is Context {
    /**
     * @dev Emitted when the sunset is triggered by `account`.
     */
    event Sunset(address account);

    /**
     * @dev Emitted when the sunrise is triggered by `account`.
     */
    event Sunrise(address account);

    bool private _sunsetModeActive;

    /**
     * @dev Initializes the contract in sunrised state.
     */
    constructor() {
        _sunsetModeActive = false;
    }

    /**
     * @dev Returns true if the sun has set, and false otherwise.
     */
    function sunsetModeActive() public view virtual returns (bool) {
        return _sunsetModeActive;
    }

    /**
     * @dev Modifier to make a function callable only when the sun is up.
     *
     * Requirements:
     *
     * - The contract must not be in sunset mode.
     */
    modifier whenSun() {
        require(!sunsetModeActive(), "Sunset: Sun has set on this contract");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the sun has set.
     *
     * Requirements:
     *
     * - The contract must be in sunset mode.
     */
    modifier whenMoon() {
        require(sunsetModeActive(), "Sunset: Sun has not set on this contract");
        _;
    }

    /**
     * @dev Triggers sunset state.
     *
     * Requirements:
     *
     * - The contract must not be in sunset already.
     */
    function _sunset() internal virtual whenSun {
        _sunsetModeActive = true;
        emit Sunset(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be in sunset mode.
     */
    function _sunrise() internal virtual whenMoon {
        _sunsetModeActive = false;
        emit Sunrise(_msgSender());
    }
}
