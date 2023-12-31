// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPriceOracle {
    function getAmountOut(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (uint256);
}
