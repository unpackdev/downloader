// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library Roles {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant REVOKER_ROLE = keccak256("REVOKER_ROLE");
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant LEDGER_WRITER_ROLE = keccak256("LEDGER_WRITER_ROLE");
    bytes32 public constant DAO_ADMIN = keccak256("DAO_ADMIN_ROLE");
    
}
