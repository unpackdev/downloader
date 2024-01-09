//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./AccessControlUpgradeable.sol";

abstract contract AccessLevel is AccessControlUpgradeable {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    function __AccessLevel_init(address owner) initializer public {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
    }
}
