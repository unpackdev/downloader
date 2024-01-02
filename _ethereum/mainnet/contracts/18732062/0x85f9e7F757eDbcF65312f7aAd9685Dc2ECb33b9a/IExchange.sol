// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IExchange {
    function swap(address tokenIn,address tokenOut,uint256 amount,uint256 minAmount) external returns (uint256);
    function getCurveInputValue(address tokenIn,address tokenOut,uint256 outAmount,uint256 maxInput)external view returns (uint256);
}
