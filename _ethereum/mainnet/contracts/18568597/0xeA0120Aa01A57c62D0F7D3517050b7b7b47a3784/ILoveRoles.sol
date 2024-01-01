// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

interface ILoveRoles {
  function grantRole(address account, string calldata role) external;

  function revokeRole(address account, string calldata role) external;

  function checkRole(address accountToCheck, string calldata role) external view returns (bool);
}
