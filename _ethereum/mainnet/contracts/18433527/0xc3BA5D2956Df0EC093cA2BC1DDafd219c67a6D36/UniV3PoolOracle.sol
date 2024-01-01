// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./IUniswapV3Pool.sol";
import "./UniV3MEVProtection.sol";

import "./CLMMPoolOracle.sol";

contract UniV3PoolOracle is CLMMPoolOracle {
    constructor(address admin, UniV3MEVProtection mevProtection_) CLMMPoolOracle(admin, mevProtection_) {}

    function getPriceAndOtherToken(
        address token,
        address pool
    ) public view override returns (uint256 priceX96, address tokenOut) {
        (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(pool).slot0();
        priceX96 = FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, Q96);

        if (IUniswapV3Pool(pool).token1() == token) {
            tokenOut = IUniswapV3Pool(pool).token0();
            priceX96 = FullMath.mulDiv(Q96, Q96, priceX96);
        } else {
            tokenOut = IUniswapV3Pool(pool).token1();
        }
    }
}
