// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

struct UniswapV3Result {
    bytes32 id;
    uint256 amountOut;
    uint24 fee;
    string message;
}

struct UniswapV3Data {
    bytes32 id;
    address tokenIn;
    address tokenOut;
    uint256 amountIn;
}
