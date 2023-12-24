// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Status
/// @notice Contains functions for managing address statuses
library Status {
    /// @notice toggles the status val of an address from 0 to 1 or 1 to 0
    /// @param self The calling contract's storage mapping containing address statuses
    /// @param addr The address that will have its status flipped
    /// @return newStatus The new status of the address (0 or 1)
    function toggle(
        mapping(address => uint256) storage self,
        address addr
    ) internal returns (uint256 newStatus) {
        unchecked {
            newStatus = 1 - self[addr];
            self[addr] = newStatus;
        }
    }
}
