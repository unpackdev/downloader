// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

contract BridgeStorageV1 {
    address public courier;
    address public guardian;
    address public bridgeToken;
    uint public fee;

    uint[] public routes;

    // chainId => nonce
    mapping (uint => uint) public crossNonce;
    // chainId => (nonce => deliver)
    mapping (uint => mapping (uint => bool)) public deliverNonces;
}
