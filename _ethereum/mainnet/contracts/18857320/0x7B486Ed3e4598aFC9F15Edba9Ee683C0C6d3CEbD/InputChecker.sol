// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

/// @title InputChecker
/// @author Florida St
/// @notice Some basic input checks.
abstract contract InputChecker {
    error AddressZeroError();

    function _checkAddressNotZero(address _address) internal pure {
        if (_address == address(0)) {
            revert AddressZeroError();
        }
    }
}
