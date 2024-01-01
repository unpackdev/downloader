// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Contains math functions
library FullMath {
    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = (a * b) / denominator;
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }

    function mulDivRoundingUp128(
        uint128 a,
        uint128 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = (uint256(a) * uint256(b)) / denominator;
        if (mulmod(uint256(a), uint256(b), denominator) > 0) {
            // require(result < type(uint256).max); // no overflow for uint128
            result++;
        }
    }
}
