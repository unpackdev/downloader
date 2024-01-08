//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

contract RolesManagerConsts {
    /**
        @notice It is the AccessControl.DEFAULT_ADMIN_ROLE role.
     */
    bytes32 public constant OWNER_ROLE = keccak256("");

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");
}
