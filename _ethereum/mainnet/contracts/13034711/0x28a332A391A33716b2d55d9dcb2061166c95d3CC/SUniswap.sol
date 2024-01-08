// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

struct UniswapResult {
    bytes32 id;
    uint256 amountOut;
    string message;
}

struct UniswapData {
    bytes32 id;
    uint256 amountIn;
    address[] path;
}
