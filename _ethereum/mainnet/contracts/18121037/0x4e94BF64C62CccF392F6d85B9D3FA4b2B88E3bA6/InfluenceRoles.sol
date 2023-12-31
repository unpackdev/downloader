// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Roles used with OZ AccessControl
library InfluenceRoles {
  bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE"); 
  bytes32 public constant TRANSFERRER_ROLE = keccak256("TRANSFERRER_ROLE");
}
