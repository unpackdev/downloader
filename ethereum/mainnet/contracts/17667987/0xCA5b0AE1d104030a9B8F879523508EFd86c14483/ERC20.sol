// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./ERC20Storage.sol";
import "./ERC20Base.sol";
import "./InterfaceDetection.sol";

/// @title ERC20 Fungible Token Standard (immutable version).
/// @dev This contract is to be used via inheritance in an immutable (non-proxied) implementation.
abstract contract ERC20 is ERC20Base, InterfaceDetection {
    /// @notice Marks the following ERC165 interface(s) as supported: ERC20, ERC20Allowance.
    constructor() {
        ERC20Storage.init();
    }
}
