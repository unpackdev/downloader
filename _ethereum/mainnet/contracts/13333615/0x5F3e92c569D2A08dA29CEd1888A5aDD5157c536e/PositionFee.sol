// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./IUniswapV3Factory.sol";
import "./IUniswapV3PoolState.sol";
import "./FixedPoint128.sol";
import "./FullMath.sol";
import "./TickMath.sol";
import "./LiquidityAmounts.sol";
import "./PositionManagerLite.sol";

library PositionFee {
    
    function getPositionDetails(uint256 tokenId, address positionManager)
        external
        view
        returns (uint256 amount0, uint256 amount1)
    {
        Position memory position = PositionManagerLite(positionManager).positions(tokenId);
        
        (address token0, address token1) = (position.token0, position.token1);

        address pool = getPool(positionManager, token0, token1, position.fee);
        (, int24 tickCurrent, , , , , ) = IUniswapV3PoolState(pool).slot0();

        (amount0, amount1) = getFees(
            pool,
            tickCurrent,
            position.tickLower,
            position.tickUpper,
            position.feeGrowthInside0LastX128,
            position.feeGrowthInside1LastX128,
            position.liquidity
        );
    }
    
    function getFees(
        address pool,
        int24 tickCurrent,
        int24 tickLower,
        int24 tickUpper,
        uint256 feeGrowthInside0Last,
        uint256 feeGrowthInside1Last,
        uint128 liquidity
    ) internal view returns (uint256 fee0, uint256 fee1) {
        (uint256 feeGrowthInside0, uint256 feeGrowthInside1) =
            getFeeGrowthInside(pool, tickCurrent, tickLower, tickUpper);

        (fee0, fee1) = (
            uint256(
                FullMath.mulDiv(
                    feeGrowthInside0 - feeGrowthInside0Last,
                    liquidity,
                    FixedPoint128.Q128
                )
            ),
            uint256(
                FullMath.mulDiv(
                    feeGrowthInside1 - feeGrowthInside1Last,
                    liquidity,
                    FixedPoint128.Q128
                )
            )
        );
    }
    
    function getFeeGrowthInside(
        address pool,
        int24 tickCurrent,
        int24 tickLower,
        int24 tickUpper
    ) internal view returns (uint256 feeGrowthInside0, uint256 feeGrowthInside1) {
        uint256 feeGrowthGlobal0 = IUniswapV3PoolState(pool).feeGrowthGlobal0X128();
        uint256 feeGrowthGlobal1 = IUniswapV3PoolState(pool).feeGrowthGlobal1X128();

        (uint256 feeGrowthBelow0, uint256 feeGrowthBelow1) =
            getFeeGrowthTick(
                pool,
                tickLower,
                tickCurrent >= tickLower,
                feeGrowthGlobal0,
                feeGrowthGlobal1
            );

        (uint256 feeGrowthAbove0, uint256 feeGrowthAbove1) =
            getFeeGrowthTick(
                pool,
                tickUpper,
                tickCurrent < tickUpper,
                feeGrowthGlobal0,
                feeGrowthGlobal1
            );

        (feeGrowthInside0, feeGrowthInside1) = (
            feeGrowthGlobal0 - feeGrowthBelow0 - feeGrowthAbove0,
            feeGrowthGlobal1 - feeGrowthBelow1 - feeGrowthAbove1
        );
    }

    function checkIdValidity(address positionManager, uint256 tokenId , address decodedPool) internal view returns(bool) {
        Position memory position = PositionManagerLite(positionManager).positions(tokenId);
        address pool = getPool(positionManager, position.token0, position.token1, position.fee);
        if (pool == decodedPool) {
            return true; 
        } 
        return false;
    }
    
    function getPool(
        address positionManager,
        address token0,
        address token1,
        uint24 fee
    ) internal view returns (address pool) {
        address factory = PositionManagerLite(positionManager).factory();
        pool = IUniswapV3Factory(factory).getPool(token0, token1, fee);
    }
    
     function getFeeGrowthTick(
        address pool,
        int24 tick,
        bool useFeeGrowthOutside,
        uint256 feeGrowthGlobal0,
        uint256 feeGrowthGlobal1
    ) internal view returns (uint256 feeGrowthTick0, uint256 feeGrowthTick1) {
        (, , uint256 feeGrowthOutside0, uint256 feeGrowthOutside1) =
            IUniswapV3PoolState(pool).ticks(tick);

        (feeGrowthTick0, feeGrowthTick1) = (useFeeGrowthOutside)
            ? (feeGrowthOutside0, feeGrowthOutside1)
            : (feeGrowthGlobal0 - feeGrowthOutside0, feeGrowthGlobal1 - feeGrowthOutside1);
    }
    
}