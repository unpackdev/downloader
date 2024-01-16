// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Initializable.sol";

contract RoleConstantsUpgradeable is Initializable {
  // addresses that have the right to interact with the storage protocol
  bytes32 public constant PROTOCOL_ADMIN = keccak256("PROTOCOL_ADMIN");

  // authorized treasurer address
  bytes32 public constant PROTOCOL_TREASURER = keccak256("PROTOCOL_TREASURER"); 

  // authorized contract addresses
  bytes32 public constant AUTHORIZED_OPERATOR = keccak256("AUTHORIZED_OPERATOR");
  
  /* Initializers */

  function __RoleConstants_init() internal initializer {
    __RoleConstants_init_unchained();
  }

  function __RoleConstants_init_unchained() internal initializer {}
} 