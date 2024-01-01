// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.6;

/// @title PercentageMath.
/// @author Morpho Labs.
/// @custom:contact security@morpho.xyz
/// @notice Optimized version of Aave V3 math library PercentageMath to conduct percentage manipulations: https://github.com/aave/aave-v3-core/blob/master/contracts/protocol/libraries/math/PercentageMath.sol
library PercentageMath {
    ///	CONSTANTS ///

    // Only direct number constants and references to such constants are supported by inline assembly.
    uint256 internal constant PERCENTAGE_FACTOR = 100_00;
    uint256 internal constant HALF_PERCENTAGE_FACTOR = 50_00;
    uint256 internal constant PERCENTAGE_FACTOR_MINUS_ONE = 100_00 - 1;
    uint256 internal constant MAX_UINT256 = 2 ** 256 - 1;
    uint256 internal constant MAX_UINT256_MINUS_HALF_PERCENTAGE_FACTOR =
        2 ** 256 - 1 - 50_00;
    uint256 internal constant MAX_UINT256_MINUS_PERCENTAGE_FACTOR_MINUS_ONE =
        2 ** 256 - 1 - (100_00 - 1);

    /// @notice Executes the bps-based multiplication (x * p), rounded half up.
    /// @param x The value to multiply by the percentage.
    /// @param percentage The percentage of the value to multiply (in bps).
    /// @return y The result of the multiplication.
    function percentMul(
        uint256 x,
        uint256 percentage
    ) internal pure returns (uint256 y) {
        // Overflow if
        //     x * percentage + HALF_PERCENTAGE_FACTOR > type(uint256).max
        // <=> percentage > 0 and x > (type(uint256).max - HALF_PERCENTAGE_FACTOR) / percentage
        assembly {
            if mul(
                percentage,
                gt(x, div(MAX_UINT256_MINUS_HALF_PERCENTAGE_FACTOR, percentage))
            ) {
                revert(0, 0)
            }

            y := div(
                add(mul(x, percentage), HALF_PERCENTAGE_FACTOR),
                PERCENTAGE_FACTOR
            )
        }
    }

    /// @notice Executes the bps-based division (x / p), rounded half up.
    /// @param x The value to divide by the percentage.
    /// @param percentage The percentage of the value to divide (in bps).
    /// @return y The result of the division.
    function percentDiv(
        uint256 x,
        uint256 percentage
    ) internal pure returns (uint256 y) {
        // 1. Division by 0 if
        //        percentage == 0
        // 2. Overflow if
        //        x * PERCENTAGE_FACTOR + percentage / 2 > type(uint256).max
        //    <=> x > (type(uint256).max - percentage / 2) / PERCENTAGE_FACTOR
        assembly {
            y := div(percentage, 2) // Temporary assignment to save gas.

            if iszero(
                mul(
                    percentage,
                    iszero(gt(x, div(sub(MAX_UINT256, y), PERCENTAGE_FACTOR)))
                )
            ) {
                revert(0, 0)
            }

            y := div(add(mul(PERCENTAGE_FACTOR, x), y), percentage)
        }
    }

    /// @notice Executes the bps-based weighted average (x * (1 - p) + y * p), rounded half up.
    /// @param x The first value, with a weight of 1 - percentage.
    /// @param y The second value, with a weight of percentage.
    /// @param percentage The weight of y, and complement of the weight of x (in bps).
    /// @return z The result of the bps-based weighted average.
    function weightedAvg(
        uint256 x,
        uint256 y,
        uint256 percentage
    ) internal pure returns (uint256 z) {
        // 1. Underflow if
        //        percentage > PERCENTAGE_FACTOR
        // 2. Overflow if
        //        y * percentage + HALF_PERCENTAGE_FACTOR > type(uint256).max
        //    <=> percentage > 0 and y > (type(uint256).max - HALF_PERCENTAGE_FACTOR) / percentage
        // 3. Overflow if
        //        x * (PERCENTAGE_FACTOR - percentage) + y * percentage + HALF_PERCENTAGE_FACTOR > type(uint256).max
        //    <=> x * (PERCENTAGE_FACTOR - percentage) > type(uint256).max - HALF_PERCENTAGE_FACTOR - y * percentage
        //    <=> PERCENTAGE_FACTOR > percentage and x > (type(uint256).max - HALF_PERCENTAGE_FACTOR - y * percentage) / (PERCENTAGE_FACTOR - percentage)
        assembly {
            z := sub(PERCENTAGE_FACTOR, percentage) // Temporary assignment to save gas.

            if or(
                gt(percentage, PERCENTAGE_FACTOR),
                or(
                    mul(
                        percentage,
                        gt(
                            y,
                            div(
                                MAX_UINT256_MINUS_HALF_PERCENTAGE_FACTOR,
                                percentage
                            )
                        )
                    ),
                    mul(
                        z,
                        gt(
                            x,
                            div(
                                sub(
                                    MAX_UINT256_MINUS_HALF_PERCENTAGE_FACTOR,
                                    mul(y, percentage)
                                ),
                                z
                            )
                        )
                    )
                )
            ) {
                revert(0, 0)
            }

            z := div(
                add(add(mul(x, z), mul(y, percentage)), HALF_PERCENTAGE_FACTOR),
                PERCENTAGE_FACTOR
            )
        }
    }
}
