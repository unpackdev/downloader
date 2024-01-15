// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

interface IPathFinder {
    struct TradePath {
        bytes path;
        uint256 expectedAmount;
        uint160[] sqrtPriceX96AfterList;
        uint32[] initializedTicksCrossedList;
        uint256 gasEstimate;
    }

    function exactInputPath(
        address tokenIn,
        address tokenOut,
        uint256 amount
    ) external returns (TradePath memory path);

    function exactOutputPath(
        address tokenIn,
        address tokenOut,
        uint256 amount
    ) external returns (TradePath memory path);

    function bestExactInputPath(
        address tokenIn,
        address tokenOut,
        uint256 amount,
        address[] memory tokens
    ) external returns (TradePath memory path);

    function bestExactOutputPath(
        address tokenIn,
        address tokenOut,
        uint256 amount,
        address[] memory tokens
    ) external returns (TradePath memory path);
}
