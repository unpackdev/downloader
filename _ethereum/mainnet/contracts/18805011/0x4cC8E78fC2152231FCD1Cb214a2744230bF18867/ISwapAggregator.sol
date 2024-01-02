// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import "./IRouterComponent.sol";

import "./SwapTask.sol";
import "./SwapQuote.sol";
import "./StrategyPathTask.sol";

interface ISwapAggregator is IRouterComponent {
    function findAllSwaps(address tokenIn, uint256 amountIn, bool isAll, StrategyPathTask memory task)
        external
        returns (StrategyPathTask[] memory);

    function findBestSwapAndWrap(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        bool isAll,
        bool revertOnNoPath,
        StrategyPathTask memory task
    ) external returns (uint256 amountOut, StrategyPathTask memory);

    function swapAndWrapAll(StrategyPathTask memory task, address target) external returns (StrategyPathTask memory);

    function getBestDirectPairSwap(SwapTask memory swapTask, address[] memory adapters, uint256 gasPriceInTokenOut)
        external
        returns (SwapQuote memory quote);
}
