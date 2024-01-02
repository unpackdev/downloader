// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INativeMetaTransaction {
    function executeMetaTransaction(
        address userAddress,
        bytes calldata functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) external payable returns (bytes memory);
}
