// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Constants {
    bytes32 constant ROLE_OWNER = keccak256(bytes("ROLE_OWNER"));
    bytes32 constant ROLE_CREATOR = keccak256(bytes("ROLE_CREATOR"));
    bytes32 constant _DOMAIN_SEPARATOR = keccak256(abi.encode(
        keccak256("EIP712Domain(string name,string version)"),
        keccak256("LiveArt"),
        keccak256("1")
    ));
}