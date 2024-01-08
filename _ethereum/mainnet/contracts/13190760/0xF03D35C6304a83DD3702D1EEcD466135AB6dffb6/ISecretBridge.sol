// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISecretBridge {
    function swap(bytes memory _recipient)
        external
        payable;
}
