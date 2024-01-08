import "./IMoneyPool.sol";

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

/**
 * @title ELYFI Connector storage
 * @author ELYSIA
 */
contract ConnectorStorage {
  struct RoleData {
    mapping(address => bool) participants;
    bytes32 admin;
  }

  mapping(bytes32 => RoleData) internal _roles;

  IMoneyPool internal _moneyPool;
}
