// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;

import "./IGUniResolver02.sol";
import "./IGUniPool.sol";
import "./IUniswapV3Pool.sol";
import "./IERC20Metadata.sol";
import "./LiquidityAmounts.sol";
import "./TickMath.sol";

contract GUniResolver02 is IGUniResolver02 {
    using TickMath for int24;

    // solhint-disable-next-line function-max-lines
    function getRebalanceParams(
        IGUniPool pool,
        uint256 amount0In,
        uint256 amount1In,
        uint256 price18Decimals
    ) external view override returns (bool zeroForOne, uint256 swapAmount) {
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

        (uint256 gross0, uint256 gross1) = _getUnderlyingOrLiquidity(pool);

        if (gross1 == 0) {
            return (false, amount1Left);
        }

        if (gross0 == 0) {
            return (true, amount0Left);
        }

        uint256 factor0 =
            10**(18 - IERC20Metadata(address(pool.token0())).decimals());
        uint256 factor1 =
            10**(18 - IERC20Metadata(address(pool.token1())).decimals());
        uint256 weightX18 =
            FullMath.mulDiv(gross0 * factor0, 1 ether, gross1 * factor1);
        uint256 proportionX18 =
            FullMath.mulDiv(weightX18, price18Decimals, 1 ether);
        uint256 factorX18 =
            FullMath.mulDiv(proportionX18, 1 ether, proportionX18 + 1 ether);

        if (amount0Left > amount1Left) {
            zeroForOne = true;
            swapAmount = FullMath.mulDiv(
                amount0Left,
                1 ether - factorX18,
                1 ether
            );
        } else if (amount1Left > amount0Left) {
            swapAmount = FullMath.mulDiv(amount1Left, factorX18, 1 ether);
        }
    }

    function _getUnderlyingOrLiquidity(IGUniPool pool)
        internal
        view
        returns (uint256 gross0, uint256 gross1)
    {
        (gross0, gross1) = pool.getUnderlyingBalances();
        if (gross0 == 0 && gross1 == 0) {
            IUniswapV3Pool uniPool = pool.pool();
            (uint160 sqrtPriceX96, , , , , , ) = uniPool.slot0();
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
