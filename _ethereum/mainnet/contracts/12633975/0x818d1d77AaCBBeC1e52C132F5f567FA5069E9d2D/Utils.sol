// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "./SafeMath.sol";
import "./ABDKMath64x64.sol";

/**
 * Library with utility functions for xU3LP
 */
library Utils {
    using SafeMath for uint256;

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
        if (secondsAgo == 0) {
            return ABDKMath64x64.fromInt(1);
        }

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
     * Helper function to calculate how much to swap to deposit / withdraw
     * In Uni Pool to satisfy the required buffer balance in xU3LP of 5%
     */
    function calculateSwapAmount(
        uint256 amount0ToMint,
        uint256 amount1ToMint,
        uint256 amount0Minted,
        uint256 amount1Minted,
        int128 liquidityRatio
    ) internal pure returns (uint256 swapAmount) {
        // formula: swapAmount =
        // (amount0ToMint * amount1Minted -
        //  amount1ToMint * amount0Minted) /
        // ((amount0Minted + amount1Minted) +
        //  liquidityRatio * (amount0ToMint + amount1ToMint))
        uint256 mul1 = amount0ToMint.mul(amount1Minted);
        uint256 mul2 = amount1ToMint.mul(amount0Minted);

        uint256 sub = subAbs(mul1, mul2);
        uint256 add1 = amount0Minted.add(amount1Minted);
        uint256 add2 =
            ABDKMath64x64.mulu(
                liquidityRatio,
                amount0ToMint.add(amount1ToMint)
            );
        uint256 add = add1.add(add2);

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

    // Subtract two numbers and return 0 if result is < 0
    function sub0(uint256 amount0, uint256 amount1)
        internal
        pure
        returns (uint256)
    {
        return amount0 >= amount1 ? amount0.sub(amount1) : 0;
    }

    function calculateFee(uint256 _value, uint256 _feeDivisor)
        internal
        pure
        returns (uint256 fee)
    {
        if (_feeDivisor > 0) {
            fee = _value.div(_feeDivisor);
        }
    }
}
