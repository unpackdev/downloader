// SPDX-License-Identifier: ISC
pragma solidity 0.7.5;
pragma abicoder v2;

import "./IUniswapV3Pool.sol";
import "./IUniswapV3Factory.sol";
import "./IUniswapV3StateMulticall.sol";

contract SolidlyV3StateMulticall is IUniswapV3StateMulticall {
    function getFullState(
        IUniswapV3Factory factory,
        address tokenIn,
        address tokenOut,
        int24 tickSpacing,
        int16 tickBitmapStart,
        int16 tickBitmapEnd
    ) external view override returns (StateResult memory state) {
        require(tickBitmapEnd >= tickBitmapStart, "tickBitmapEnd < tickBitmapStart");

        state = _fillStateWithoutTicks(factory, tokenIn, tokenOut, tickSpacing, tickBitmapStart, tickBitmapEnd);
        state.ticks = _calcTicksFromBitMap(factory, tokenIn, tokenOut, tickSpacing, state.tickBitmap);
    }

    function getFullStateWithoutTicks(
        IUniswapV3Factory factory,
        address tokenIn,
        address tokenOut,
        int24 tickSpacing,
        int16 tickBitmapStart,
        int16 tickBitmapEnd
    ) external view override returns (StateResult memory state) {
        require(tickBitmapEnd >= tickBitmapStart, "tickBitmapEnd < tickBitmapStart");

        return _fillStateWithoutTicks(factory, tokenIn, tokenOut, tickSpacing, tickBitmapStart, tickBitmapEnd);
    }

    function getFullStateWithRelativeBitmaps(
        IUniswapV3Factory factory,
        address tokenIn,
        address tokenOut,
        int24 tickSpacing,
        int16 leftBitmapAmount,
        int16 rightBitmapAmount
    ) external view override returns (StateResult memory state) {
        require(leftBitmapAmount > 0, "leftBitmapAmount <= 0");
        require(rightBitmapAmount > 0, "rightBitmapAmount <= 0");

        state = _fillStateWithoutBitmapsAndTicks(factory, tokenIn, tokenOut, tickSpacing);
        int16 currentBitmapIndex = _getBitmapIndexFromTick(state.slot0.tick / state.tickSpacing);

        state.tickBitmap = _calcTickBitmaps(
            factory,
            tokenIn,
            tokenOut,
            tickSpacing,
            currentBitmapIndex - leftBitmapAmount,
            currentBitmapIndex + rightBitmapAmount
        );
        state.ticks = _calcTicksFromBitMap(factory, tokenIn, tokenOut, tickSpacing, state.tickBitmap);
    }

    function getAdditionalBitmapWithTicks(
        IUniswapV3Factory factory,
        address tokenIn,
        address tokenOut,
        int24 tickSpacing,
        int16 tickBitmapStart,
        int16 tickBitmapEnd
    ) external view override returns (TickBitMapMappings[] memory tickBitmap, TickInfoMappings[] memory ticks) {
        require(tickBitmapEnd >= tickBitmapStart, "tickBitmapEnd < tickBitmapStart");

        tickBitmap = _calcTickBitmaps(factory, tokenIn, tokenOut, tickSpacing, tickBitmapStart, tickBitmapEnd);
        ticks = _calcTicksFromBitMap(factory, tokenIn, tokenOut, tickSpacing, tickBitmap);
    }

    function getAdditionalBitmapWithoutTicks(
        IUniswapV3Factory factory,
        address tokenIn,
        address tokenOut,
        int24 tickSpacing,
        int16 tickBitmapStart,
        int16 tickBitmapEnd
    ) external view override returns (TickBitMapMappings[] memory tickBitmap) {
        require(tickBitmapEnd >= tickBitmapStart, "tickBitmapEnd < tickBitmapStart");

        return _calcTickBitmaps(factory, tokenIn, tokenOut, tickSpacing, tickBitmapStart, tickBitmapEnd);
    }

    function _fillStateWithoutTicks(
        IUniswapV3Factory factory,
        address tokenIn,
        address tokenOut,
        int24 tickSpacing,
        int16 tickBitmapStart,
        int16 tickBitmapEnd
    ) internal view returns (StateResult memory state) {
        state = _fillStateWithoutBitmapsAndTicks(factory, tokenIn, tokenOut, tickSpacing);
        state.tickBitmap = _calcTickBitmaps(factory, tokenIn, tokenOut, tickSpacing, tickBitmapStart, tickBitmapEnd);
    }

    function _fillStateWithoutBitmapsAndTicks(
        IUniswapV3Factory factory,
        address tokenIn,
        address tokenOut,
        int24 tickSpacing
    ) internal view returns (StateResult memory state) {
        IUniswapV3Pool pool = _getPool(factory, tokenIn, tokenOut, tickSpacing);

        state.pool = pool;
        state.blockTimestamp = block.timestamp;
        state.liquidity = pool.liquidity();
        state.tickSpacing = pool.tickSpacing();
        state.maxLiquidityPerTick = pool.maxLiquidityPerTick();

        (
            state.slot0.sqrtPriceX96,
            state.slot0.tick,
            state.slot0.fee,
            state.slot0.unlocked
        ) = pool.slot0();
    }

    function _calcTickBitmaps(
        IUniswapV3Factory factory,
        address tokenIn,
        address tokenOut,
        int24 tickSpacing,
        int16 tickBitmapStart,
        int16 tickBitmapEnd
    ) internal view returns (TickBitMapMappings[] memory tickBitmap) {
        IUniswapV3Pool pool = _getPool(factory, tokenIn, tokenOut, tickSpacing);

        uint256 numberOfPopulatedBitmaps = 0;
        for (int256 i = tickBitmapStart; i <= tickBitmapEnd; i++) {
            uint256 bitmap = pool.tickBitmap(int16(i));
            if (bitmap == 0) continue;
            numberOfPopulatedBitmaps++;
        }

        tickBitmap = new TickBitMapMappings[](numberOfPopulatedBitmaps);
        uint256 globalIndex = 0;
        for (int256 i = tickBitmapStart; i <= tickBitmapEnd; i++) {
            int16 index = int16(i);
            uint256 bitmap = pool.tickBitmap(index);
            if (bitmap == 0) continue;

            tickBitmap[globalIndex] = TickBitMapMappings({ index: index, value: bitmap });
            globalIndex++;
        }
    }

    function _calcTicksFromBitMap(
        IUniswapV3Factory factory,
        address tokenIn,
        address tokenOut,
        int24 tickSpacing,
        TickBitMapMappings[] memory tickBitmap
    ) internal view returns (TickInfoMappings[] memory ticks) {
        IUniswapV3Pool pool = _getPool(factory, tokenIn, tokenOut, tickSpacing);

        uint256 numberOfPopulatedTicks = 0;
        for (uint256 i = 0; i < tickBitmap.length; i++) {
            uint256 bitmap = tickBitmap[i].value;

            for (uint256 j = 0; j < 256; j++) {
                if (bitmap & (1 << j) > 0) numberOfPopulatedTicks++;
            }
        }

        ticks = new TickInfoMappings[](numberOfPopulatedTicks);
        int24 poolTickSpacing = pool.tickSpacing();

        uint256 globalIndex = 0;
        for (uint256 i = 0; i < tickBitmap.length; i++) {
            uint256 bitmap = tickBitmap[i].value;

            for (uint256 j = 0; j < 256; j++) {
                if (bitmap & (1 << j) > 0) {
                    int24 populatedTick = ((int24(tickBitmap[i].index) << 8) + int24(j)) * poolTickSpacing;

                    ticks[globalIndex].index = populatedTick;
                    TickInfo memory newTickInfo = ticks[globalIndex].value;

                    (
                        newTickInfo.liquidityGross,
                        newTickInfo.liquidityNet,
                        newTickInfo.initialized
                    ) = pool.ticks(populatedTick);

                    globalIndex++;
                }
            }
        }
    }

    function _getPool(
        IUniswapV3Factory factory,
        address tokenIn,
        address tokenOut,
        int24 tickSpacing
    ) internal view returns (IUniswapV3Pool pool) {
        pool = IUniswapV3Pool(factory.getPool(tokenIn, tokenOut, tickSpacing));
        require(address(pool) != address(0), "Pool does not exist");
    }

    function _getBitmapIndexFromTick(int24 tick) internal pure returns (int16) {
        return int16(tick >> 8);
    }
}