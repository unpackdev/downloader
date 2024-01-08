// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;

import "./IGUniResolver.sol";
import "./IGUniPool.sol";
import "./IUniswapV3Pool.sol";
import "./SafeERC20.sol";
import "./LiquidityAmounts.sol";
import "./TickMath.sol";

contract GUniResolver is IGUniResolver {
    using SafeERC20 for IERC20;
    using TickMath for int24;

    function getPoolUnderlyingBalances(IGUniPool pool)
        public
        view
        override
        returns (uint256 amount0, uint256 amount1)
    {
        return pool.getUnderlyingBalances();
    }

    function getUnderlyingBalances(IGUniPool pool, uint256 balance)
        external
        view
        override
        returns (uint256 amount0, uint256 amount1)
    {
        (uint256 gross0, uint256 gross1) = pool.getUnderlyingBalances();
        uint256 supply = pool.totalSupply();
        amount0 = FullMath.mulDiv(gross0, balance, supply);
        amount1 = FullMath.mulDiv(gross1, balance, supply);
    }

    // solhint-disable-next-line function-max-lines
    function getRebalanceParams(
        IGUniPool pool,
        uint256 amount0In,
        uint256 amount1In,
        uint16 slippageBPS
    )
        external
        view
        override
        returns (
            bool zeroForOne,
            uint256 swapAmount,
            uint160 swapThreshold
        )
    {
        IUniswapV3Pool uniPool = pool.pool();

        (uint160 sqrtPriceX96, , , , , , ) = uniPool.slot0();
        uint160 rawAmountSlippage = (sqrtPriceX96 * slippageBPS) / 10000;

        uint256 amount0Left;
        uint256 amount1Left;
        try pool.getMintAmounts(amount0In, amount1In) returns (
            uint256 amount0,
            uint256 amount1,
            uint256
        ) {
            amount0Left = amount0In - amount0;
            amount1Left = amount1In - amount1;
        } catch {
            amount0Left = amount0In;
            amount1Left = amount1In;
        }

        (uint256 gross0, uint256 gross1) =
            _getUnderlyingOrLiquidity(pool, sqrtPriceX96);

        if (gross1 == 0) {
            return (false, amount1Left, sqrtPriceX96 + rawAmountSlippage);
        }

        if (gross0 == 0) {
            return (true, amount0Left, sqrtPriceX96 - rawAmountSlippage);
        }

        uint256 weightX18 = FullMath.mulDiv(gross0, 1 ether, gross1);
        uint256 priceX96 = FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, (2**96));
        uint256 proportionX18 = FullMath.mulDiv(weightX18, priceX96, (2**96));
        uint256 factorX18 =
            FullMath.mulDiv(proportionX18, 1 ether, proportionX18 + 1 ether);

        if (amount0Left > amount1Left) {
            zeroForOne = true;
            swapThreshold = sqrtPriceX96 - rawAmountSlippage;
            swapAmount = FullMath.mulDiv(
                amount0Left,
                1 ether - factorX18,
                1 ether
            );
        } else if (amount1Left > amount0Left) {
            swapThreshold = sqrtPriceX96 + rawAmountSlippage;
            swapAmount = FullMath.mulDiv(amount1Left, factorX18, 1 ether);
        }
    }

    function _getUnderlyingOrLiquidity(IGUniPool pool, uint160 sqrtPriceX96)
        internal
        view
        returns (uint256 gross0, uint256 gross1)
    {
        (gross0, gross1) = pool.getUnderlyingBalances();
        if (gross0 == 0 && gross1 == 0) {
            uint160 lowerSqrtPrice = pool.lowerTick().getSqrtRatioAtTick();
            uint160 upperSqrtPrice = pool.upperTick().getSqrtRatioAtTick();
            (gross0, gross1) = LiquidityAmounts.getAmountsForLiquidity(
                sqrtPriceX96,
                lowerSqrtPrice,
                upperSqrtPrice,
                1 ether
            );
        }
    }
}
