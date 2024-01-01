// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDEXRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract SwapExecutor {
    address private immutable uniswapRouter;
    address private immutable sushiswapRouter;

    constructor(
        address _uniswapRouter,
        address _sushiswapRouter
    ) {
        uniswapRouter = _uniswapRouter;
        sushiswapRouter = _sushiswapRouter;
    }

    enum DexChoice { Uniswap, Sushiswap }

    function executeSwap(
        DexChoice dex,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {
        address router = dex == DexChoice.Uniswap ? uniswapRouter : sushiswapRouter;
        IDEXRouter(router).swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline);
    }
}