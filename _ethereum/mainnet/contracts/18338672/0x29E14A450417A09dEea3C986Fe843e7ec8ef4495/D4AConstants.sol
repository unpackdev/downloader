// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

uint256 constant BASIS_POINT = 10_000;

bytes32 constant DEFAULT_ADMIN_ROLE = 0;
bytes32 constant PROTOCOL_ROLE = keccak256("PROTOCOL_ROLE");
bytes32 constant OPERATION_ROLE = keccak256("OPERATION_ROLE");
bytes32 constant DAO_ROLE = keccak256("DAO_ROLE");
bytes32 constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

uint256 constant BASIC_DAO_RESERVE_NFT_NUMBER = 1000;
