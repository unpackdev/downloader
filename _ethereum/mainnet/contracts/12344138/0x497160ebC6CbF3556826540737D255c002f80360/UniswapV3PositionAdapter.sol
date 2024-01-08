// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "./IUniswapV3Factory.sol";
import "./IUniswapV3PoolState.sol";
import "./FixedPoint128.sol";
import "./FullMath.sol";
import "./TickMath.sol";
import "./LiquidityAmounts.sol";

import "./IUniswapV3PositionAdapter.sol";
import "./INonfungiblePositionManager.sol";

contract UniswapV3PositionAdapter is IUniswapV3PositionAdapter {
    /// @inheritdoc IUniswapV3PositionAdapter
    function getPositionDetails(address positionManager, uint256 tokenId)
        external
        view
        override
        returns (PositionDetail[2] memory positionDetails)
    {
        // Get the position from the position manager
        Position memory position = INonfungiblePositionManager(positionManager).positions(tokenId);

        // Save `token{0,1}` and `tokensOwed{0,1}` from the position
        (positionDetails[0].token, positionDetails[1].token) = (position.token0, position.token1);
        (positionDetails[0].tokensOwed, positionDetails[1].tokensOwed) = (
            position.tokensOwed0,
            position.tokensOwed1
        );

        // Compute pool address and its current state
        address pool = getPool(positionManager, position.token0, position.token1, position.fee);
        (uint160 sqrtPriceX96, int24 tickCurrent, , , , , ) = IUniswapV3PoolState(pool).slot0();

        // Compute amounts that are currently in the pool
        (positionDetails[0].amount, positionDetails[1].amount) = getAmounts(
            sqrtPriceX96,
            position.tickLower,
            position.tickUpper,
            position.liquidity
        );

        // Compute fee growths that are not in `tokensOwed{0,1}` yet
        (positionDetails[0].feeGrowth, positionDetails[1].feeGrowth) = getFeeGrowths(
            pool,
            tickCurrent,
            position.tickLower,
            position.tickUpper,
            position.feeGrowthInside0LastX128,
            position.feeGrowthInside1LastX128,
            position.liquidity
        );
    }

    /// @notice Computes the pool's address given the position's parameters
    /// @param positionManager The address of the Uniswap V3 NonfungiblePositionManager contract
    /// @param token0 Position's `token0`
    /// @param token1 Position's `token1`
    /// @param fee Position's `fee`
    /// @return pool Pool's address
    function getPool(
        address positionManager,
        address token0,
        address token1,
        uint24 fee
    ) internal view returns (address pool) {
        address factory = INonfungiblePositionManager(positionManager).factory();
        pool = IUniswapV3Factory(factory).getPool(token0, token1, fee);
    }

    /// @notice Computes `feeGrowth{0,1}` -- fee growths that are not in `tokensOwed{0,1}` yet
    /// @param pool Pool's address
    /// @param tickCurrent Pool's current tick
    /// @param tickLower Position's lower tick
    /// @param tickUpper Position's upper tick
    /// @param feeGrowthInside0Last Position's fee growth for `token0`
    /// @param feeGrowthInside1Last Position's fee growth for `token1`
    /// @param liquidity Position's liquidity
    /// @return feeGrowth0 Amount of fees that are not saved in the position for `token0`
    /// @return feeGrowth1 Amount of fees that are not saved in the position for `token1`
    function getFeeGrowths(
        address pool,
        int24 tickCurrent,
        int24 tickLower,
        int24 tickUpper,
        uint256 feeGrowthInside0Last,
        uint256 feeGrowthInside1Last,
        uint128 liquidity
    ) internal view returns (uint256 feeGrowth0, uint256 feeGrowth1) {
        (uint256 feeGrowthInside0, uint256 feeGrowthInside1) =
            getFeeGrowthInside(pool, tickCurrent, tickLower, tickUpper);

        (feeGrowth0, feeGrowth1) = (
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

    /// @notice Computes `feeGrowthInside{0,1}`
    /// @param pool Pool's address
    /// @param tickCurrent Pool's current tick
    /// @param tickLower Position's lower tick
    /// @param tickUpper Position's upper tick
    /// @return feeGrowthInside0 Pool's fee growth for the position for `token0`
    /// @return feeGrowthInside1 Pool's fee growth for the position for `token1`
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

    /// @notice Computes `feeGrowthTick{0,1}` for the one of boundary ticks (above or below)
    /// @param pool Pool's address
    /// @param tick Pool's boundary tick
    /// @param useFeeGrowthOutside Whether to use only `feeGrowthOutside`
    /// @param feeGrowthGlobal0 Pool's global fee growth for `token0`
    /// @param feeGrowthGlobal1 Pool's global fee growth for `token1`
    /// @return feeGrowthTick0 Pool's fee growth for the tick for `token0`
    /// @return feeGrowthTick1 Pool's fee growth for the tick for `token1`
    function getFeeGrowthTick(
        address pool,
        int24 tick,
        bool useFeeGrowthOutside,
        uint256 feeGrowthGlobal0,
        uint256 feeGrowthGlobal1
    ) internal view returns (uint256 feeGrowthTick0, uint256 feeGrowthTick1) {
        (, , uint256 feeGrowthOutside0, uint256 feeGrowthOutside1, , , , ) =
            IUniswapV3PoolState(pool).ticks(tick);

        (feeGrowthTick0, feeGrowthTick1) = (useFeeGrowthOutside)
            ? (feeGrowthOutside0, feeGrowthOutside1)
            : (feeGrowthGlobal0 - feeGrowthOutside0, feeGrowthGlobal1 - feeGrowthOutside1);
    }

    /// @notice Computes `amount{0,1}` -- amounts that are currently in the pool
    /// @param sqrtPriceX96 Pool's current price
    /// @param tickLower Position's lower tick
    /// @param tickUpper Position's upper tick
    /// @param liquidity Position's liquidity
    /// @return amount0 Amount of `token0` that are currently in the pool
    /// @return amount1 Amount of `token1` that are currently in the pool
    function getAmounts(
        uint160 sqrtPriceX96,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtPriceX96,
            TickMath.getSqrtRatioAtTick(tickLower),
            TickMath.getSqrtRatioAtTick(tickUpper),
            liquidity
        );
    }
}
