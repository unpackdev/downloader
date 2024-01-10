// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 *  @dev AdminController dds functionality for admins to controll a contract, similar to Ownable but more verbose
 */
abstract contract AdminController {
    /// @dev makes sure the address is an admin
    modifier onlyAdmin() {
        require(_isAdmin(), "not admin");
        _;
    }

    /// @dev is the sender an admin
    function _isAdmin() internal view virtual returns (bool);
}
