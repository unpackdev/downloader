// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ERC1155SupplyUpgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "./INonfungiblePositionManager.sol";
import "./IUniswapV3Factory.sol";
import "./IUniswapV3Pool.sol";
import "./IERC721Receiver.sol";
import "./FullMath.sol";
import "./PositionKey.sol";
import "./FixedPoint128.sol";

library UniswapV3Position {
    error OnlyPositionManager();

    struct UniswapV3PositionData {
        IUniswapV3Pool pool;
        address token0;
        address token1;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        uint128 tokensOwed0;
        uint128 tokensOwed1;
    }

    function get(INonfungiblePositionManager positionManager, IUniswapV3Factory factory, uint256 tokenId)
        internal
        view
        returns (UniswapV3PositionData memory position)
    {
        (
            ,
            ,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        ) = positionManager.positions(tokenId);
        position = UniswapV3PositionData({
            pool: IUniswapV3Pool(factory.getPool(token0, token1, fee)),
            token0: token0,
            token1: token1,
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: liquidity,
            feeGrowthInside0LastX128: feeGrowthInside0LastX128,
            feeGrowthInside1LastX128: feeGrowthInside1LastX128,
            tokensOwed0: tokensOwed0,
            tokensOwed1: tokensOwed1
        });
    }

    /// @dev Logic is taken from uniswap-v3/core/contracts/libraries/Tick.sol
    function _getFeeGrowthInside(UniswapV3PositionData memory position)
        internal
        view
        returns (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128)
    {
        unchecked {
            (, int24 tickCurrent,,,,,) = position.pool.slot0();

            uint256 feeGrowthGlobal0X128 = position.pool.feeGrowthGlobal0X128();
            uint256 feeGrowthGlobal1X128 = position.pool.feeGrowthGlobal1X128();

            (,, uint256 feeGrowthOutsideLower0X128, uint256 feeGrowthOutsideLower1X128,,,,) =
                position.pool.ticks(position.tickLower);
            (,, uint256 feeGrowthOutsideUpper0X128, uint256 feeGrowthOutsideUpper1X128,,,,) =
                position.pool.ticks(position.tickUpper);

            // calculate fee growth below
            uint256 feeGrowthBelow0X128;
            uint256 feeGrowthBelow1X128;
            if (tickCurrent >= position.tickLower) {
                feeGrowthBelow0X128 = feeGrowthOutsideLower0X128;
                feeGrowthBelow1X128 = feeGrowthOutsideLower1X128;
            } else {
                feeGrowthBelow0X128 = feeGrowthGlobal0X128 - feeGrowthOutsideLower0X128;
                feeGrowthBelow1X128 = feeGrowthGlobal1X128 - feeGrowthOutsideLower1X128;
            }

            // calculate fee growth above
            uint256 feeGrowthAbove0X128;
            uint256 feeGrowthAbove1X128;
            if (tickCurrent < position.tickUpper) {
                feeGrowthAbove0X128 = feeGrowthOutsideUpper0X128;
                feeGrowthAbove1X128 = feeGrowthOutsideUpper1X128;
            } else {
                feeGrowthAbove0X128 = feeGrowthGlobal0X128 - feeGrowthOutsideUpper0X128;
                feeGrowthAbove1X128 = feeGrowthGlobal1X128 - feeGrowthOutsideUpper1X128;
            }

            feeGrowthInside0X128 = feeGrowthGlobal0X128 - feeGrowthBelow0X128 - feeGrowthAbove0X128;
            feeGrowthInside1X128 = feeGrowthGlobal1X128 - feeGrowthBelow1X128 - feeGrowthAbove1X128;
        }
    }

    function getPendingFees(UniswapV3PositionData memory position)
        internal
        view
        returns (uint256 amount0, uint256 amount1)
    {
        // Non-zero positions can't have unclaimed fees by designe of position manager
        if (position.liquidity == 0) {
            return (position.tokensOwed0, position.tokensOwed1);
        }

        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) = _getFeeGrowthInside(position);
        unchecked {
            // overflow in fee growth subtraction is expected
            amount0 = position.tokensOwed0
                + uint128(
                    FullMath.mulDiv(
                        feeGrowthInside0X128 - position.feeGrowthInside0LastX128, position.liquidity, FixedPoint128.Q128
                    )
                );
            amount1 = position.tokensOwed1
                + uint128(
                    FullMath.mulDiv(
                        feeGrowthInside1X128 - position.feeGrowthInside1LastX128, position.liquidity, FixedPoint128.Q128
                    )
                );
        }
    }
}
