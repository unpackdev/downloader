// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./DefaultCallbackHandler.sol";

contract EthscriptionsFallbackHandler is DefaultCallbackHandler {
    fallback() external {
        require(msg.data.length % 32 == 0, "Invalid concatenated hashes length");
    }
}