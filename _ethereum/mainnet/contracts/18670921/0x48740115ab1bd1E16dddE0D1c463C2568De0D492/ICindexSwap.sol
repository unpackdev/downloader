// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

interface ICindexSwap {

    struct SwapData {
        address extRouter;
        bytes extCalldata;
        bool needScale;
    }
    function swap(address tokenIn, uint256 amountIn, SwapData calldata swapData) external payable;
}