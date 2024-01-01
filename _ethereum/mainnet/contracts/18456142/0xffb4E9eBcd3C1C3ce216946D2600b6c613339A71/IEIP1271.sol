// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IEIP1271 {
    function isValidSignature(
        bytes32 eip712Hash,
        bytes calldata signature
    ) external view returns (bytes4 magicValue);
}
