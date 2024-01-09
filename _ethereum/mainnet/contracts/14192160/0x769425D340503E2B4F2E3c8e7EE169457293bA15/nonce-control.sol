// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

abstract contract NonceControl {
    mapping(uint256 => bool) usedNonces;
    modifier onlyValidNonce(uint256 _nonce) {
        require(!usedNonces[_nonce]);
        usedNonces[_nonce]=true;
        _;
    }
}