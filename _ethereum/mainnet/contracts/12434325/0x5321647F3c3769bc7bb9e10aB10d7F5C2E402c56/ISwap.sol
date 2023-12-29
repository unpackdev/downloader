//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

interface ISwap {
    struct Swap {
        address pool;
        address tokenIn;
        address tokenOut;
        uint256 swapAmount; // tokenInAmount / tokenOutAmount
        uint256 limitReturnAmount; // minAmountOut / maxAmountIn
        uint256 maxPrice;
    }
}
