// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Variables {
    address internal _owner;

    mapping(bytes32 => bool) public executeMapping;

    mapping(bytes32 => address) public actionDsaAddress;

    uint256 public vnonce;

    bool internal _initialized;

    bool internal _initializing;

    uint256 internal _status;
}
