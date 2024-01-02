// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

abstract contract BaseContractRoles {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PROTOCOL_ROLE = keccak256("PROTOCOL_ROLE");
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 public constant CREDIT_MINTER_ROLE =
        keccak256("CREDIT_MINTER_ROLE");
}
