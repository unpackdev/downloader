// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IUniswapV3Pool.sol";
import "./TickMath.sol";
// import "./FullMath.sol";

library UniswapV3Twap {
    uint256 internal constant Q192 = 0x1000000000000000000000000000000000000000000000000;

    function getSqrtTwapX96(
        address uniswapV3Pool,
        uint32 twapInterval
    ) public view returns (uint160 sqrtPriceX96) {
        if (twapInterval == 0) {
            // return the current price if twapInterval == 0
            (sqrtPriceX96, , , , , , ) = IUniswapV3Pool(uniswapV3Pool).slot0();
        } else {
            uint32[] memory secondsAgos = new uint32[](2);
            secondsAgos[0] = twapInterval; // from (before)
            secondsAgos[1] = 0; // to (now)

            (int56[] memory tickCumulatives, ) = IUniswapV3Pool(uniswapV3Pool).observe(secondsAgos);

            // tick(imprecise as it's an integer) to price
            sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
                int24((tickCumulatives[1] - tickCumulatives[0]) / int56(int32(twapInterval)))
            );
        }
    }

    function getTwap(
        uint256 amount,
        address token,
        address pool,
        uint32 twapInterval
    ) public view returns (uint256) {
        uint160 sqrtPriceX96 = getSqrtTwapX96(pool, twapInterval);
        address token0 = IUniswapV3Pool(pool).token0();
        if (token == token0) {
            // return FullMath.mulDiv(amount, (uint256(sqrtPriceX96) * uint256(sqrtPriceX96)), Q192);
            return (amount * (uint256(sqrtPriceX96) * uint256(sqrtPriceX96))) / Q192;
        } else {
            // return FullMath.mulDiv(amount, Q192, (uint256(sqrtPriceX96) * uint256(sqrtPriceX96)));
            return (amount * Q192) / (uint256(sqrtPriceX96) * uint256(sqrtPriceX96));
        }
    }
}
