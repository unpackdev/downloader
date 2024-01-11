//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.4;

import "./IUniswapV3Pool.sol";
import "./TickMath.sol";
import "./FixedPoint96.sol";
import "./FullMath.sol";

contract TWAPPriceGetter {
    function getPrice(address poolAddress, uint32 twapInterval) public view returns (uint256 priceX96) {
        if (twapInterval == 0) {
            (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(poolAddress).slot0();
						return FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96);
        } else {
            uint32[] memory secondsAgos = new uint32[](2);
            secondsAgos[0] = twapInterval;
            secondsAgos[1] = 0;
            (int56[] memory tickCumulatives, ) = IUniswapV3Pool(poolAddress).observe(secondsAgos);
            uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
                int24((tickCumulatives[1] - tickCumulatives[0]) / twapInterval)
            );
						return FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96);
        }
    }
}