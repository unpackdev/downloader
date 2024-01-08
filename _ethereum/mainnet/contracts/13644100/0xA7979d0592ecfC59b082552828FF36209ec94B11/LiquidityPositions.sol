// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
pragma abicoder v2;

import "./PositionKey.sol";
import "./LiquidityAmounts.sol";
import "./TickMath.sol";
import "./IUniswapV3Pool.sol";
import "./IUniswapLiquidityManager.sol";
import "./LiquidityReserves.sol";
import "./LowGasSafeMath.sol";

// import "./LowGasSafeMath.sol";

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityPositions {
    using LowGasSafeMath for uint256;

    struct Vars {
        int24 baseTickLower;
        int24 baseTickUpper;
        int24 rangeTickLower;
        int24 rangeTickUpper;
        uint256 fees0;
        uint256 fees1;
        uint256 totalLiquidity;
        uint256 baseAmount0;
        uint256 baseAmount1;
        uint256 rangeAmount0;
        uint256 rangeAmount1;
    }

    function getTotalAmounts(
        IUniswapLiquidityManager.LiquidityPosition memory self,
        address pool
    )
        internal
        view
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 totalLiquidity
        )
    {
        IUniswapV3Pool uniswapPool = IUniswapV3Pool(pool);
        Vars memory localVars;

        (localVars.baseAmount0, localVars.baseAmount1) = LiquidityReserves
            .getPositionTokenAmounts(
                self.baseTickLower,
                self.baseTickUpper,
                uniswapPool,
                self.baseLiquidity
            );
        (localVars.rangeAmount0, localVars.rangeAmount1) = LiquidityReserves
            .getPositionTokenAmounts(
                self.rangeTickLower,
                self.rangeTickUpper,
                uniswapPool,
                self.rangeLiquidity
            );

        amount0 = localVars.baseAmount0.add(localVars.rangeAmount0);
        amount1 = localVars.baseAmount1.add(localVars.rangeAmount1);
        totalLiquidity = self.totalLiquidity;
    }

    function getPoolDetails(address pool)
        internal
        view
        returns (
            address token0,
            address token1,
            uint24 fee,
            uint16 poolCardinality,
            uint128 liquidity,
            uint160 sqrtPriceX96,
            int24 currentTick
        )
    {
        IUniswapV3Pool uniswapPool = IUniswapV3Pool(pool);
        token0 = uniswapPool.token0();
        token1 = uniswapPool.token1();
        fee = uniswapPool.fee();
        liquidity = uniswapPool.liquidity();
        (sqrtPriceX96, currentTick, , poolCardinality, , , ) = uniswapPool.slot0();
    }

    function shouldReadjust(
        address pool,
        int24 baseTickLower,
        int24 baseTickUpper
    ) internal view returns (bool readjust) {
        int24 tickSpacing = 0;
        (, , , , , , int24 currentTick) = getPoolDetails(pool);
        int24 threshold = tickSpacing; // will increase thershold for mainnet to 1200
        if (
            (currentTick < (baseTickLower + threshold)) ||
            (currentTick > (baseTickUpper - threshold))
        ) {
            readjust = true;
        } else {
            readjust = false;
        }
    }
}
