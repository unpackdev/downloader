// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract AccessRoleCommon {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER");
    bytes32 public constant CLAIMER_ROLE = keccak256("CLAIMER");
}
