// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library TimelockRoles {
  bytes32 public constant TERMINATION_ADMIN_ROLE = keccak256("TERMINATION_ADMIN");
  bytes32 public constant TIMELOCK_CREATOR_ROLE = keccak256("TIMELOCK_CREATOR");
}