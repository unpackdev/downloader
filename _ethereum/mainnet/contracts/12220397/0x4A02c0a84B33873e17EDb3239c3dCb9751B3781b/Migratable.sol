// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.7.0;

import "./AccessControlUpgradeable.sol";

abstract contract Migratable is AccessControlUpgradeable {
    bytes32 public constant MIGRATOR_ROLE = keccak256("MIGRATOR_ROLE");

    modifier onlyMigrator() {
        require(
            hasRole(MIGRATOR_ROLE, _msgSender()),
            "Caller is not a migrator"
        );
        _;
    }
} 