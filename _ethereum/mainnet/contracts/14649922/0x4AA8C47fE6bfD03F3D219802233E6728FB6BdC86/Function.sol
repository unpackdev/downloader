// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Function {
    bytes data;
    uint256 value;
    address externalAddress;
    bytes4 checkFunctionSignature;
    bytes4 execFunctionSignature;
}
