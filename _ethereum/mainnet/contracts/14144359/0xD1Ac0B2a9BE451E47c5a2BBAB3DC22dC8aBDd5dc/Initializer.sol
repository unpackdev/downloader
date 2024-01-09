/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "./Address.sol";

abstract contract Initializer {
    using Address for address;

    bool private _initialized;

    modifier initializer() {
        require(!_initialized || !address(this).isContract(), "Initializer/Already Initialized");
        _initialized = true;
        _;
    }
}
