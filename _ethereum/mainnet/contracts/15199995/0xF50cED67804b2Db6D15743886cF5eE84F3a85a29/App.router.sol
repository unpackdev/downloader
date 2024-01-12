//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ISwapRouter.sol";
import "./IUniswapV2Callee.sol";
import "./Withdraw.sol";
import "./SwapSushiAndV2.sol";
import "./SwapSushiAndV3.sol";
import "./SwapV2AndV3.sol";

contract AppRouter is
    IUniswapV2Callee,
    IUniswapV3SwapCallback,
    SwapSushiAndV2Router,
    SwapSushiAndV3Router,
    SwapV2AndV3Router,
    Withdraw
{
    event AccountLog(uint256 amount);

    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        (uint256 amountIn, uint8 swapType, ) = abi.decode(
            data,
            (uint256, uint8, uint24)
        );
        // swapType枚举值
        // 1: uniswapV2 -> sushi的回调
        // 2: sushi -> uniswapV2的回调
        // 3: uniswapV2 -> uniswapV3的回调
        // 4: sushi -> uniswapV3的回调
        if (swapType == 1) {
            uniswapV2ForSushiCallback(amountIn, amount0, amount1);
        }
        if (swapType == 2) {
            sushiForUniswapV2CallBack(amountIn, amount0, amount1);
        }
        if (swapType == 3) {
            sushiForUniswapV3Callback(amountIn, amount0, amount1, data);
        }
        if (swapType == 4) {
            uniswapV2ForUniswapV3Callback(amountIn, amount0, amount1, data);
        }
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override {
        (, , , uint8 swapType) = abi.decode(
            data,
            (uint256, address, address, uint8)
        );
        if (swapType == 5) {
            uniswapV3ForSushiCallback(amount0Delta, amount1Delta, data);
        }
        if (swapType == 6) {
            uniswapV3ForV2Callback(amount0Delta, amount1Delta, data);
        }
    }

    // 回调函数，避免被重入攻击
    receive() external payable {
        emit AccountLog(msg.value);
    }
}
