// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

/**
 * @title Access role interface
 */
interface IRole {
  // Check if an address has a role
  function hasRole(bytes32 role, address account) external view returns (bool);
}
