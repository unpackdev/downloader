// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./LiquidityAmounts.sol";
import "./TickMath.sol";
import "./FullMath.sol";

/// @author YLDR <admin@apyflow.com>
library ConcentratedLiquidityLibrary {
    function getAmountsForLiquidityProviding(
        uint160 sqrtPriceAX96,
        uint160 sqrtPriceX96,
        uint160 sqrtPriceBX96,
        uint256 assets
    ) internal pure returns (uint256 amountFor0, uint256 amountFor1) {
        if (sqrtPriceX96 <= sqrtPriceAX96) {
            amountFor0 = assets;
        } else if (sqrtPriceX96 < sqrtPriceBX96) {
            uint256 n = FullMath.mulDiv(sqrtPriceBX96, sqrtPriceX96 - sqrtPriceAX96, FixedPoint96.Q96);
            uint256 d = FullMath.mulDiv(sqrtPriceX96, sqrtPriceBX96 - sqrtPriceX96, FixedPoint96.Q96);
            uint256 x = FullMath.mulDiv(n, FixedPoint96.Q96, d);
            amountFor0 = FullMath.mulDiv(assets, FixedPoint96.Q96, x + FixedPoint96.Q96);
            amountFor1 = assets - amountFor0;
        } else {
            amountFor1 = assets;
        }
    }
}
