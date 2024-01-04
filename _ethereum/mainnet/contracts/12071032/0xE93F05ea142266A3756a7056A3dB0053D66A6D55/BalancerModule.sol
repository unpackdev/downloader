// SPDX-License-Identifier: None
pragma solidity >=0.7.5;
pragma abicoder v2;

import "./IERC20.sol";
import "./LibERC20Token.sol";
import "./ISlingshotModule.sol";

interface IBalancerPool {
    /// @dev Sell `tokenAmountIn` of `tokenIn` and receive `tokenOut`.
    /// @param tokenIn The token being sold
    /// @param tokenAmountIn The amount of `tokenIn` to sell.
    /// @param tokenOut The token being bought.
    /// @param minAmountOut The minimum amount of `tokenOut` to buy.
    /// @param maxPrice The maximum value for `spotPriceAfter`.
    /// @return tokenAmountOut The amount of `tokenOut` bought.
    /// @return spotPriceAfter The new marginal spot price of the given
    ///         token pair for this pool.
    function swapExactAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);
}

/// @title Slingshot Balancer Module
contract BalancerModule is ISlingshotModule {
    using LibERC20Token for IERC20;

    /// @param pool Balancer pool to trade on
    /// @param tokenIn Address of token sold
    /// @param tokenOut Address of token bought
    /// @param totalAmountIn Amount of token sold
    /// @param tradeAll If true, it overrides totalAmountIn with current token balance
    function swap(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 totalAmountIn,
        bool tradeAll
    ) public payable {
        if (tradeAll) {
            totalAmountIn = IERC20(tokenIn).balanceOf(address(this));
        }

        IERC20(tokenIn).approveIfBelow(pool, totalAmountIn);

        IBalancerPool(pool).swapExactAmountIn(
            tokenIn,
            totalAmountIn,
            tokenOut,
            1,          // minAmountOut
            uint256(-1) // maxPrice
        );
    }
}
