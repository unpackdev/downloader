// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

interface IRole {
  function hasRole(bytes32 role, address account) external view returns (bool);
}
