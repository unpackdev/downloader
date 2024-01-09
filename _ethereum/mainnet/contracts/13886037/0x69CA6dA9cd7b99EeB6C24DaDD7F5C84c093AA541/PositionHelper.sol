// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./LiquidityAmounts.sol";
import "./TickMath.sol";
import "./FullMath.sol";
import "./FixedPoint128.sol";
import "./IUniswapV3Pool.sol";
import "./SafeMath.sol";

library PositionHelper {

    using SafeMath for uint256;

    struct Position {
        uint128 principal0;
        uint128 principal1;
        address poolAddress;
        int24 lowerTick;
        int24 upperTick;
        int24 tickSpacing;
        bool status; // True - InvestIn   False - NotInvest
    }

    /* ========== VIEW ========== */

    function _positionInfo(
        Position memory position
    ) internal view returns(uint128, uint256, uint256, uint256, uint256){
        // Pool OBJ
        IUniswapV3Pool pool = IUniswapV3Pool(position.poolAddress);
        // Get Position Key
        bytes32 positionKey = keccak256(abi.encodePacked(address(this), position.lowerTick, position.upperTick));
        // Get Position Detail
        return pool.positions(positionKey);
    }

    function _tickInfo(
        IUniswapV3Pool pool,
        int24 tick
    ) internal view returns (uint256 feeGrowthOutside0X128, uint256 feeGrowthOutside1X128) {
        // liquidityGross\liquidityNet\0\1\tickCumulativeOutside\secondsPerLiquidityOutsideX128\secondsOutside\initialized
        ( , , feeGrowthOutside0X128, feeGrowthOutside1X128, , , , ) = pool.ticks(tick);
    }

    function _getFeeGrowthInside(
        Position memory position
    ) internal view returns (uint256, uint256) {
        IUniswapV3Pool pool = IUniswapV3Pool(position.poolAddress);
        (int24 tickCurrent, uint256 feeGrowthGlobal0X128, uint256 feeGrowthGlobal1X128) = _poolInfo(pool);
        // calculate fee growth below
        (uint256 feeGrowthBelow0X128, uint256 feeGrowthBelow1X128) = _tickInfo(pool, position.lowerTick);
        if (tickCurrent < position.lowerTick) {
            feeGrowthBelow0X128 = feeGrowthGlobal0X128 - feeGrowthBelow0X128;
            feeGrowthBelow1X128 = feeGrowthGlobal1X128 - feeGrowthBelow1X128;
        }
        // calculate fee growth above
        (uint256 feeGrowthAbove0X128, uint256 feeGrowthAbove1X128) = _tickInfo(pool, position.upperTick);
        if (tickCurrent >= position.upperTick) {
            feeGrowthAbove0X128 = feeGrowthGlobal0X128 - feeGrowthAbove0X128;
            feeGrowthAbove1X128 = feeGrowthGlobal1X128 - feeGrowthAbove1X128;
        }
        // calculate inside
        uint256 feeGrowthInside0X128 = feeGrowthGlobal0X128 - feeGrowthBelow0X128 - feeGrowthAbove0X128;
        uint256 feeGrowthInside1X128 = feeGrowthGlobal1X128 - feeGrowthBelow1X128 - feeGrowthAbove1X128;
        return(feeGrowthInside0X128, feeGrowthInside1X128);
    }

    function _getPendingAmounts(
        Position memory position,
        uint128 liquidity,
        uint256 feeGrowthInside0LastX128,
        uint256 feeGrowthInside1LastX128
    ) internal view returns(uint256 tokensPending0, uint256 tokensPending1) {

        // feeInside
        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) = _getFeeGrowthInside(position);

        // pending calculate
        tokensPending0 = FullMath.mulDiv(
            feeGrowthInside0X128 - feeGrowthInside0LastX128,
            liquidity,
            FixedPoint128.Q128
        );
        tokensPending1 = FullMath.mulDiv(
            feeGrowthInside1X128 - feeGrowthInside1LastX128,
            liquidity,
            FixedPoint128.Q128
        );
    }

    function _getTotalAmounts(Position memory position, uint8 _performanceFee) internal view returns (uint256 total0, uint256 total1) {
        // Pool OBJ
        IUniswapV3Pool pool = IUniswapV3Pool(position.poolAddress);
        // position info
        (
        uint128 liquidity,
        uint256 feeGrowthInside0LastX128,
        uint256 feeGrowthInside1LastX128,
        uint256 owned0,
        uint256 owned1
        ) = _positionInfo(position);
        // liquidity Amount
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
        (total0, total1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtRatioX96,
            TickMath.getSqrtRatioAtTick(position.lowerTick),
            TickMath.getSqrtRatioAtTick(position.upperTick),
            liquidity
        );
        // get Pending
        (uint256 pending0, uint256 pending1) = _getPendingAmounts(position, liquidity, feeGrowthInside0LastX128, feeGrowthInside1LastX128);
        total0 = total0.add(pending0).add(owned0);
        total1 = total1.add(pending1).add(owned1);
        if (_performanceFee > 0) {
            total0 = total0.sub(pending0.div(_performanceFee));
            total1 = total1.sub(pending1.div(_performanceFee));
        }
    }

    function _poolInfo(IUniswapV3Pool pool) internal view returns (int24, uint256, uint256) {
        ( , int24 tick, , , , , ) = pool.slot0();
        uint256 feeGrowthGlobal0X128 = pool.feeGrowthGlobal0X128();
        uint256 feeGrowthGlobal1X128 = pool.feeGrowthGlobal1X128();
        // return
        return (tick, feeGrowthGlobal0X128, feeGrowthGlobal1X128);
    }

    /* ========== BASE FUNCTION ========== */

    function _addLiquidity(
        Position memory position,
        uint128 liquidity
    ) internal returns (uint256 amount0, uint256 amount1){
        // Pool OBJ
        IUniswapV3Pool pool = IUniswapV3Pool(position.poolAddress);
        // add Liquidity on Uniswap
        (amount0, amount1) = pool.mint(
            address(this),
            position.lowerTick,
            position.upperTick,
            liquidity,
            ""
        );
    }

    function _burnLiquidity(
        Position memory position,
        uint128 liquidity
    ) internal returns (uint256 amount0, uint256 amount1) {
        // Pool OBJ
        IUniswapV3Pool pool = IUniswapV3Pool(position.poolAddress);
        (amount0, amount1) = pool.burn(position.lowerTick, position.upperTick, liquidity);
    }

    function _collect(
        Position memory position,
        address to,
        uint128 amount0,
        uint128 amount1
    ) internal returns (uint256 collect0, uint256 collect1) {
        // Pool OBJ
        IUniswapV3Pool pool = IUniswapV3Pool(position.poolAddress);
        // collect ALL to Vault
        (collect0, collect1) = pool.collect(
            to,
            position.lowerTick,
            position.upperTick,
            amount0,
            amount1
        );
    }

    /* ========== SENIOR FUNCTION ========== */

    function _addAll(
        Position memory position,
        uint256 balance0,
        uint256 balance1
    ) internal returns(uint256 amount0, uint256 amount1){
        // Pool OBJ
        IUniswapV3Pool pool = IUniswapV3Pool(position.poolAddress);
        // Calculate Liquidity
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtRatioX96,
            TickMath.getSqrtRatioAtTick(position.lowerTick),
            TickMath.getSqrtRatioAtTick(position.upperTick),
            balance0,
            balance1
        );
        // Add to Pool
        if (liquidity > 0) {
            (amount0, amount1) = _addLiquidity(position, liquidity);
        }
    }

    function _burnAll(
        Position memory position
    ) internal returns(uint256, uint256, uint256, uint256) {
        // Read Liq
        (uint128 liquidity, , , , ) = _positionInfo(position);
        if(liquidity == 0) return (0, 0, 0, 0);
        return _burn(position, liquidity);
    }

    function _burn(
        Position memory position,
        uint128 liquidity
    ) internal returns(uint256 amount0, uint256 amount1, uint256 fee0, uint256 fee1) {
        // Burn
        (fee0, fee1) = _burnLiquidity(position, liquidity);
        // Collect
        (amount0, amount1) = _collect(position, address(this), type(uint128).max, type(uint128).max);
        fee0 = amount0 - fee0;
        fee1 = amount1 - fee1;
    }

    function _burnSpecific(
        Position memory position,
        uint128 liquidity,
        address to
    ) internal returns(uint256 amount0, uint256 amount1, uint fee0, uint fee1){
        // Burn
        (amount0, amount1) = _burnLiquidity(position, liquidity);
        // Collect to user
        _collect(position, to, uint128(amount0), uint128(amount1));
        // Collect to Vault
        (fee0, fee1) = _collect(position, address(this), type(uint128).max, type(uint128).max);
    }

    function _getReBalanceTicks(
        Position memory position,
        int24 reBalanceThreshold,
        int24 band
    ) internal view returns (bool status, int24 lowerTick, int24 upperTick) {
        // get Current Tick
        IUniswapV3Pool pool = IUniswapV3Pool(position.poolAddress);
        ( , int24 tick, , , , , ) = pool.slot0();
        bool lowerRebalance;
        // Check status
        if (position.status) {
            int24 middleTick = (position.lowerTick + position.upperTick) / 2;
            if (middleTick - tick >= reBalanceThreshold) {
                status = true;
                lowerRebalance = true;
            }else if(tick - middleTick >= reBalanceThreshold){
                status = true;
            }
        } else {
            status = true;
        }
        // get new ticks
        if (status) {
            if(lowerRebalance && (tick % position.tickSpacing != 0)){
                tick = _floor(tick, position.tickSpacing) + position.tickSpacing ;
            }else{
                tick = _floor(tick, position.tickSpacing);
            }
            band = _floor(band, position.tickSpacing);
            lowerTick = tick - band;
            upperTick = tick + band;
        }
    }

    function checkDiffTick(Position memory position, int24 _tick, uint24 _diffTick) internal view {
        // get Current Tick
        IUniswapV3Pool pool = IUniswapV3Pool(position.poolAddress);
        ( , int24 tick, , , , , ) = pool.slot0();
        require(tick - _tick < int24(_diffTick) && _tick - tick < int24(_diffTick), "DIFF TICK");
    }

    function _floor(int24 tick, int24 _tickSpacing) internal pure returns (int24) {
        int24 compressed = tick / _tickSpacing;
        if (tick < 0 && tick % _tickSpacing != 0) compressed--;
        return compressed * _tickSpacing;
    }

}
