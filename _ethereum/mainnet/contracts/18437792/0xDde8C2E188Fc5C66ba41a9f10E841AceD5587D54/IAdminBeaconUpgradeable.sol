// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IAdminBeaconUpgradeable {
  function isAdmin(address account) external view returns (bool);
}