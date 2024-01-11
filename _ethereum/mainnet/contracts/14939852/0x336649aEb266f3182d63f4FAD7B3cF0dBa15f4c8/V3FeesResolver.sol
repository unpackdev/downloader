// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;

import "./IArrakisVaultV1.sol";
import "./FullMath.sol";

contract V3FeesResolver {
    struct ComputeFeesEarned {
        uint256 feeGrowthInsideLast;
        uint256 liquidity;
        int24 tick;
        int24 lowerTick;
        int24 upperTick;
        bool isZero;
        IUniswapV3Pool pool;
    }

    // solhint-disable-next-line function-max-lines
    function getUncollectedFees(IArrakisVaultV1 vault)
        external
        view
        returns (uint256 fee0, uint256 fee1)
    {
        IUniswapV3Pool pool = vault.pool();
        int24 lowerTick = vault.lowerTick();
        int24 upperTick = vault.upperTick();
        bytes32 positionId = vault.getPositionID();
        (, int24 tick, , , , ,) = pool.slot0();

        {
            (
                uint128 liquidity,
                uint256 feeGrowthInside0Last,
                ,
                uint128 tokensOwed0,
            ) = pool.positions(positionId);
            ComputeFeesEarned memory args0 = ComputeFeesEarned({
                feeGrowthInsideLast: feeGrowthInside0Last,
                liquidity: liquidity,
                tick: tick,
                lowerTick: lowerTick,
                upperTick: upperTick,
                isZero: true,
                pool: pool
            });
            fee0 = computeFeesEarned(args0) + uint256(tokensOwed0);
        }

        {
            (
                uint128 liquidity,
                ,
                uint256 feeGrowthInside1Last,
                ,
                uint128 tokensOwed1
            ) = pool.positions(positionId);
            ComputeFeesEarned memory args1 = ComputeFeesEarned({
                feeGrowthInsideLast: feeGrowthInside1Last,
                liquidity: liquidity,
                tick: tick,
                lowerTick: lowerTick,
                upperTick: upperTick,
                isZero: false,
                pool: pool
            });
            fee1 = computeFeesEarned(args1) + uint256(tokensOwed1);
        }
    }

    // solhint-disable-next-line function-max-lines
    function computeFeesEarned(ComputeFeesEarned memory computeFeesEarned_)
        public
        view
        returns (uint256 fee)
    {
        uint256 feeGrowthOutsideLower;
        uint256 feeGrowthOutsideUpper;
        uint256 feeGrowthGlobal;
        if (computeFeesEarned_.isZero) {
            feeGrowthGlobal = computeFeesEarned_.pool.feeGrowthGlobal0X128();
            (, , feeGrowthOutsideLower, , , , , ) = computeFeesEarned_
                .pool
                .ticks(computeFeesEarned_.lowerTick);
            (, , feeGrowthOutsideUpper, , , , , ) = computeFeesEarned_
                .pool
                .ticks(computeFeesEarned_.upperTick);
        } else {
            feeGrowthGlobal = computeFeesEarned_.pool.feeGrowthGlobal1X128();
            (, , , feeGrowthOutsideLower, , , , ) = computeFeesEarned_
                .pool
                .ticks(computeFeesEarned_.lowerTick);
            (, , , feeGrowthOutsideUpper, , , , ) = computeFeesEarned_
                .pool
                .ticks(computeFeesEarned_.upperTick);
        }

        unchecked {
            // calculate fee growth below
            uint256 feeGrowthBelow;
            if (computeFeesEarned_.tick >= computeFeesEarned_.lowerTick) {
                feeGrowthBelow = feeGrowthOutsideLower;
            } else {
                feeGrowthBelow = feeGrowthGlobal - feeGrowthOutsideLower;
            }

            // calculate fee growth above
            uint256 feeGrowthAbove;
            if (computeFeesEarned_.tick < computeFeesEarned_.upperTick) {
                feeGrowthAbove = feeGrowthOutsideUpper;
            } else {
                feeGrowthAbove = feeGrowthGlobal - feeGrowthOutsideUpper;
            }

            uint256 feeGrowthInside = feeGrowthGlobal -
                feeGrowthBelow -
                feeGrowthAbove;
            fee = FullMath.mulDiv(
                computeFeesEarned_.liquidity,
                feeGrowthInside - computeFeesEarned_.feeGrowthInsideLast,
                0x100000000000000000000000000000000
            );
        }
    }
}