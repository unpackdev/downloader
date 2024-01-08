// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "./SafeMath.sol";
import "./ABDKMath64x64.sol";

/**
 * Library with utility functions for xAssetCLR
 */
library Utils {
    using SafeMath for uint256;

    struct AmountsMinted {
        uint256 amount0ToMint;
        uint256 amount1ToMint;
        uint256 amount0Minted;
        uint256 amount1Minted;
    }

    /**
        Get asset 1 twap price for the period of [now - secondsAgo, now]
     */
    function getTWAP(int56[] memory prices, uint32 secondsAgo)
        internal
        pure
        returns (int128)
    {
        // Formula is
        // 1.0001 ^ (currentPrice - pastPrice) / secondsAgo
        require(secondsAgo != 0, "Cannot get twap for 0 seconds");

        int256 diff = int256(prices[1]) - int256(prices[0]);
        uint256 priceDiff = diff < 0 ? uint256(-diff) : uint256(diff);
        int128 fraction = ABDKMath64x64.divu(priceDiff, uint256(secondsAgo));

        int128 twap =
            ABDKMath64x64.pow(
                ABDKMath64x64.divu(10001, 10000),
                uint256(ABDKMath64x64.toUInt(fraction))
            );

        // This is necessary because we cannot call .pow on unsigned integers
        // And thus when asset0Price > asset1Price we need to reverse the value
        twap = diff < 0 ? ABDKMath64x64.inv(twap) : twap;
        return twap;
    }

    /**
     * Helper function to calculate how much to swap when
     * staking or withdrawing from Uni V3 Pools
     * Goal of this function is to calibrate the staking tokens amounts
     * When we want to stake, for example, 100 token0 and 10 token1
     * But pool price demands 100 token0 and 40 token1
     * We cannot directly stake 100 t0 and 10 t1, so we swap enough
     * to be able to stake the value of 100 t0 and 10 t1
     */
    function calculateSwapAmount(
        AmountsMinted memory amountsMinted,
        int128 liquidityRatio,
        uint256 midPrice
    ) internal pure returns (uint256 swapAmount) {
        // formula is more complicated than xU3LP case
        // it includes the asset prices, and considers the swap impact on the pool
        // base formula is this:
        // n - swap amt, x - amount 0 to mint, y - amount 1 to mint,
        // z - amount 0 minted, t - amount 1 minted, p0 - pool mid price
        // l - liquidity ratio (current mint liquidity vs total pool liq)
        // (X - n) / (Y + n * p0) = (Z + l * n) / (T - l * n * p0) ->
        // n = (X * T - Y * Z) / (p0 * l * X + p0 * Z + l * Y + T)
        uint256 mul1 =
            amountsMinted.amount0ToMint.mul(amountsMinted.amount1Minted);
        uint256 mul2 =
            amountsMinted.amount1ToMint.mul(amountsMinted.amount0Minted);
        uint256 sub = subAbs(mul1, mul2);
        uint256 add1 =
            ABDKMath64x64.mulu(liquidityRatio, amountsMinted.amount1ToMint);
        uint256 add2 =
            midPrice
                .mul(
                ABDKMath64x64.mulu(liquidityRatio, amountsMinted.amount0ToMint)
            )
                .div(1e12);
        uint256 add3 = midPrice.mul(amountsMinted.amount0Minted).div(1e12);
        uint256 add = add1.add(add2).add(add3).add(amountsMinted.amount1Minted);

        // Some numbers are too big to fit in ABDK's div 128-bit representation
        // So calculate the root of the equation and then raise to the 2nd power
        int128 nRatio =
            ABDKMath64x64.divu(
                ABDKMath64x64.sqrtu(sub),
                ABDKMath64x64.sqrtu(add)
            );
        int64 n = ABDKMath64x64.toInt(nRatio);
        swapAmount = uint256(n)**2;
    }

    // comparator for 32-bit timestamps
    // @return bool Whether a <= b
    function lte(
        uint32 time,
        uint32 a,
        uint32 b
    ) internal pure returns (bool) {
        if (a <= time && b <= time) return a <= b;

        uint256 aAdjusted = a > time ? a : a + 2**32;
        uint256 bAdjusted = b > time ? b : b + 2**32;

        return aAdjusted <= bAdjusted;
    }

    // Subtract two numbers and return absolute value
    function subAbs(uint256 amount0, uint256 amount1)
        internal
        pure
        returns (uint256)
    {
        return amount0 >= amount1 ? amount0.sub(amount1) : amount1.sub(amount0);
    }
}
