// SPDX-License-Identifier: MIT
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

import "./INonfungiblePositionManager.sol";
import "./IUniswapV3Factory.sol";
import "./IUniswapV3Pool.sol";
import "./SqrtPriceMath.sol";
import "./TickMath.sol";
import "./FullMath.sol";
import "./FixedPoint128.sol";
import "./IPositionViewer.sol";

contract PositionViewer is IPositionViewer {
    address public constant factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address public constant positionManager = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

    // Contract version
    uint256 public constant version = 1;
    
    function query(uint256 tokenId)
        public
        view
        returns (
            address token0,
            address token1,
            uint24 fee,
            uint256 amount0,
            uint256 amount1,
            uint256 fee0,
            uint256 fee1
        )
    {
        // query position data
        (
            ,
            ,
            address t0,
            address t1,
            uint24 f,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 positionFeeGrowthInside0LastX128,
            uint256 positionFeeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        ) = INonfungiblePositionManager(positionManager).positions(tokenId);
        token0 = t0;
        token1 = t1;
        fee = f;

        // query pool data
        address poolAddr = IUniswapV3Factory(factory).getPool(token0, token1, fee);
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddr);
        (uint160 sqrtPriceX96, int24 tick, , , , , ) = pool.slot0();
        uint256 feeGrowthGlobal0X128 = pool.feeGrowthGlobal0X128();
        uint256 feeGrowthGlobal1X128 = pool.feeGrowthGlobal1X128();
        (, , uint256 lowerFeeGrowthOutside0X128, uint256 lowerFeeGrowthOutside1X128, , , , ) = pool.ticks(tickLower);
        (, , uint256 upperFeeGrowthOutside0X128, uint256 upperFeeGrowthOutside1X128, , , , ) = pool.ticks(tickUpper);

        // calc amount0 amount1
        int256 a0;
        int256 a1;
        int128 liquidityDelta = -int128(liquidity);
        if (liquidityDelta != 0) {
            if (tick < tickLower) {
                a0 = SqrtPriceMath.getAmount0Delta(
                    TickMath.getSqrtRatioAtTick(tickLower),
                    TickMath.getSqrtRatioAtTick(tickUpper),
                    liquidityDelta
                );
            } else if (tick < tickUpper) {
                a0 = SqrtPriceMath.getAmount0Delta(
                    sqrtPriceX96,
                    TickMath.getSqrtRatioAtTick(tickUpper),
                    liquidityDelta
                );
                a1 = SqrtPriceMath.getAmount1Delta(
                    TickMath.getSqrtRatioAtTick(tickLower),
                    sqrtPriceX96,
                    liquidityDelta
                );
            } else {
                a1 = SqrtPriceMath.getAmount1Delta(
                    TickMath.getSqrtRatioAtTick(tickLower),
                    TickMath.getSqrtRatioAtTick(tickUpper),
                    liquidityDelta
                );
            }
        }
        amount0 = uint256(-a0);
        amount1 = uint256(-a1);

        // calc fee0 fee1
        fee0 = tokensOwed0;
        fee1 = tokensOwed1;
        if (liquidity > 0) {
            uint256 feeGrowthBelow0X128;
            uint256 feeGrowthBelow1X128;
            if (tick >= tickLower) {
                feeGrowthBelow0X128 = lowerFeeGrowthOutside0X128;
                feeGrowthBelow1X128 = lowerFeeGrowthOutside1X128;
            } else {
                feeGrowthBelow0X128 = feeGrowthGlobal0X128 - lowerFeeGrowthOutside0X128;
                feeGrowthBelow1X128 = feeGrowthGlobal1X128 - lowerFeeGrowthOutside1X128;
            }
            uint256 feeGrowthAbove0X128;
            uint256 feeGrowthAbove1X128;
            if (tick < tickUpper) {
                feeGrowthAbove0X128 = upperFeeGrowthOutside0X128;
                feeGrowthAbove1X128 = upperFeeGrowthOutside1X128;
            } else {
                feeGrowthAbove0X128 = feeGrowthGlobal0X128 - upperFeeGrowthOutside0X128;
                feeGrowthAbove1X128 = feeGrowthGlobal1X128 - upperFeeGrowthOutside1X128;
            }
            uint256 feeGrowthInside0X128;
            uint256 feeGrowthInside1X128;
            unchecked {
                feeGrowthInside0X128 = feeGrowthGlobal0X128 - feeGrowthBelow0X128 - feeGrowthAbove0X128;
                feeGrowthInside1X128 = feeGrowthGlobal1X128 - feeGrowthBelow1X128 - feeGrowthAbove1X128;
            }

            fee0 += FullMath.mulDiv(
                feeGrowthInside0X128 - positionFeeGrowthInside0LastX128,
                liquidity,
                FixedPoint128.Q128
            );
            fee1 += FullMath.mulDiv(
                feeGrowthInside1X128 - positionFeeGrowthInside1LastX128,
                liquidity,
                FixedPoint128.Q128
            );
        }
    }
}
