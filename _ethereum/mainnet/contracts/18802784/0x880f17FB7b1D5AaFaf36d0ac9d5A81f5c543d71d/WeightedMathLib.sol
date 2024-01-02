// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.21;

import "./FixedPointMathLib.sol";
import "./SafeCastLib.sol";

library WeightedMathLib {
    /// -----------------------------------------------------------------------
    /// Dependencies
    /// -----------------------------------------------------------------------

    using SafeCastLib for *;

    using FixedPointMathLib for *;

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    /// @dev Thrown when `amountIn` exceeds `MAX_PERCENTAGE_IN`, which is imposed by balancer.
    error AmountInTooLarge();

    /// @dev Thrown when `amountOut` exceeds `MAX_PERCENTAGE_OUT`, which is imposed by balancer.
    error AmountOutTooLarge();

    /// -----------------------------------------------------------------------
    /// Constants
    /// -----------------------------------------------------------------------

    /// @dev Maximum relative error allowed for fixed-point math operations (10^(-14)).
    uint256 internal constant MAX_POW_RELATIVE_ERROR = 10000;

    /// @dev Maximum percentage of reserveIn allowed to be swapped in when using `getAmountOut` (30%).
    uint256 internal constant MAX_PERCENTAGE_IN = 0.3 ether;

    /// @dev Maximum percentage of reserveOut allowed to be swapped out when using `getAmountIn` (30%).
    uint256 internal constant MAX_PERCENTAGE_OUT = 0.3 ether;

    /// -----------------------------------------------------------------------
    ///  Weighted Arithmetic
    /// -----------------------------------------------------------------------

    /// @notice Calculate the spot price given reserves and weights of two assets in a pool.
    /// @param reserveIn The reserve of the input asset in the pool.
    /// @param reserveOut The reserve of the output asset in the pool.
    /// @param weightIn The weight of the input asset in the pool.
    /// @param weightOut The weight of the output asset in the pool.
    function getSpotPrice(
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 weightIn,
        uint256 weightOut
    ) internal pure returns (uint256) {
        // -----------------------------------------------------------------------
        // (reserveIn / weightIn) / (reserveOut / weightOut)
        // -----------------------------------------------------------------------

        return reserveIn.divWad(weightIn).divWad(reserveOut.divWad(weightOut));
    }

    /// @notice Calculate the invariant of a weighted pool given reserves and weights of the assets.
    /// @param reserves An array of reserves for all the assets in the pool.
    /// @param weights An array of weights for all the assets in the pool.
    function getInvariant(uint256[] memory reserves, uint256[] memory weights)
        internal
        pure
        returns (uint256 invariant)
    {
        // -----------------------------------------------------------------------
        //   ____
        //   ⎟⎟          weight
        //   ⎟⎟  reserve ^     = i
        //   n = totalAssets
        // -----------------------------------------------------------------------

        invariant = 1e18;

        uint256 n = weights.length;

        for (uint256 i; i < n; i = i.rawAdd(1)) {
            invariant = invariant.mulWad(int256(reserves[i]).powWad(int256(weights[i])).toUint256());
        }
    }

    /// @notice Calculate the invariant of a weighted pool given two reserves and weights.
    /// @dev Optimized for pools that contain exactly two assets.
    /// @param reserveIn The reserve of the input asset in the pool.
    /// @param reserveOut The reserve of the output asset in the pool.
    /// @param weightIn The weight of the input asset in the pool.
    /// @param weightOut The weight of the output asset in the pool.
    function getInvariant(
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 weightIn,
        uint256 weightOut
    ) internal pure returns (uint256 invariant) {
        // -----------------------------------------------------------------------
        //   ____
        //   ⎟⎟          weight
        //   ⎟⎟  reserve ^     = i
        //   n = 2
        // -----------------------------------------------------------------------

        invariant = 1e18.mulWad(powWad(reserveIn, weightIn)).mulWad(powWad(reserveOut, weightOut));
    }

    /// @notice Calculate the amount of input asset required to get a specific amount of output asset from the pool.
    /// @param amountOut The desired amount of output asset.
    /// @param reserveIn The reserve of the input asset in the pool.
    /// @param reserveOut The reserve of the output asset in the pool.
    /// @param weightIn The weight of the input asset in the pool.
    /// @param weightOut The weight of the output asset in the pool.
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 weightIn,
        uint256 weightOut
    ) internal pure returns (uint256) {
        unchecked {
            // -----------------------------------------------------------------------
            //
            //             ⎛                       ⎛weightIn ⎞    ⎞
            //             ⎜                        ─────────      ⎟
            //             ⎜                       ⎝weightOut⎠    ⎟
            //             ⎜⎛     reserveOut      ⎞               ⎟
            // reserveIn ⋅    ─────────────────────             - 1
            //             ⎝⎝reserveOut - amountIn⎠               ⎠
            // -----------------------------------------------------------------------

            // Assert `amountOut` cannot exceed `MAX_PERCENTAGE_OUT`.
            if (amountOut > reserveOut.mulWad(MAX_PERCENTAGE_OUT)) {
                revert AmountOutTooLarge();
            }

            // `MAX_PERCENTAGE_OUT` check ensures `amountOut` is always less than `reserveOut`.
            return reserveIn.mulWadUp(
                powWadUp(
                    reserveOut.divWadUp(reserveOut.rawSub(amountOut)), weightOut.divWadUp(weightIn)
                ) - 1 ether
            );
        }
    }

    /// @notice Calculate the amount of output asset received by providing a specific amount of input asset to the pool.
    /// @param amountIn The amount of input asset provided.
    /// @param reserveIn The reserve of the input asset in the pool.
    /// @param reserveOut The reserve of the output asset in the pool.
    /// @param weightIn The weight of the input asset in the pool.
    /// @param weightOut The weight of the output asset in the pool.
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 weightIn,
        uint256 weightOut
    ) internal pure returns (uint256) {
        // -----------------------------------------------------------------------
        //
        //             ⎛                          ⎛weightIn ⎞⎞
        //             ⎜                           ─────────  ⎟
        //             ⎜                          ⎝weightOut⎠⎟
        //             ⎜    ⎛      reserveIn     ⎞           ⎟
        // reserveOut ⋅  1 -  ────────────────────
        //             ⎝    ⎝reserveIn + amountIn⎠           ⎠
        // -----------------------------------------------------------------------

        // Assert `amountIn` cannot exceed `MAX_PERCENTAGE_IN`.
        if (amountIn > reserveIn.mulWad(MAX_PERCENTAGE_IN)) {
            revert AmountInTooLarge();
        }

        return reserveOut.mulWad(
            1e18.rawSub(
                powWadUp(reserveIn.divWadUp(reserveIn + amountIn), weightIn.divWad(weightOut))
            )
        );
    }

    function linearInterpolation(uint256 x, uint256 y, uint256 i, uint256 n)
        internal
        pure
        returns (uint256)
    {
        // -----------------------------------------------------------------------
        //
        //         ⎛ |x - y| ⎞
        // x ± i ⋅   ─────────
        //         ⎝    n    ⎠
        // -----------------------------------------------------------------------

        return x > y
            ? x.rawSub(x.rawSub(y).mulDiv(i.min(n), n))
            : x.rawAdd(y.rawSub(x).mulDiv(i.min(n), n));
    }

    /// -----------------------------------------------------------------------
    /// Fixed-point Arithmetic
    /// -----------------------------------------------------------------------

    function powWad(uint256 x, uint256 y) internal pure returns (uint256) {
        if (y == 1 ether) {
            return x;
        } else if (y == 2 ether) {
            return x.mulWad(x);
        } else if (y == 4 ether) {
            uint256 square = x.mulWad(x);
            return square.mulWad(square);
        }

        return int256(x).powWad(int256(y)).toUint256();
    }

    function powWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        if (y == 1 ether) {
            return x;
        } else if (y == 2 ether) {
            return x.mulWadUp(x);
        } else if (y == 4 ether) {
            uint256 square = x.mulWadUp(x);
            return square.mulWadUp(square);
        }

        uint256 power = int256(x).powWad(int256(y)).toUint256();

        return power + power.mulWadUp(MAX_POW_RELATIVE_ERROR) + 1;
    }
}
