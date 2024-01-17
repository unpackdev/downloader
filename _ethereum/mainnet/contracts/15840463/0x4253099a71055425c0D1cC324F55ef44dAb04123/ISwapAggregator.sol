// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import "./IRouterComponent.sol";

import "./SwapTask.sol";
import "./SwapQuote.sol";
import "./StrategyPathTask.sol";

interface ISwapAggregator is IRouterComponent {
    function findAllSwaps(
        address tokenIn,
        uint256 amountIn,
        bool isAll,
        StrategyPathTask memory task
    ) external returns (StrategyPathTask[] memory);

    function findBestSwapQuote(
        SwapTask memory swapTask,
        address[] memory adapters
    ) external returns (SwapQuote memory bestQuote);

    function findBestSwap(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        StrategyPathTask memory task
    ) external returns (uint256 amountOut, StrategyPathTask memory);

    function findBestAllInputSwap(
        address tokenIn,
        address tokenOut,
        StrategyPathTask memory task
    ) external returns (uint256 amountOut, StrategyPathTask memory);

    function findBestSwapOrRevert(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        StrategyPathTask memory task
    ) external returns (uint256 amountOut, StrategyPathTask memory);

    function findBestAllInputSwapOrRevert(
        address tokenIn,
        address tokenOut,
        StrategyPathTask memory task
    ) external returns (uint256 amountOut, StrategyPathTask memory);

    function swapAllNormalTokens(StrategyPathTask memory task, address target)
        external
        returns (StrategyPathTask memory);

    function getBestDirectPairSwap(
        SwapTask memory swapTask,
        address[] memory adapters,
        uint256 gasPriceInTokenOut
    ) external returns (SwapQuote memory quote);
}
