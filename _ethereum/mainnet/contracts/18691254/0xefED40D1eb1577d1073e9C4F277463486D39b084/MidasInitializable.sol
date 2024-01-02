// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./AccessControlUpgradeable.sol";

/**
 * @title MidasInitializable
 * @author RedDuck Software
 * @notice Base Initializable contract that implements constructor
 * that calls _disableInitializers() to prevent
 * initialization of implementation contract
 */
abstract contract MidasInitializable is Initializable {
    constructor() {
        _disableInitializers();
    }
}
