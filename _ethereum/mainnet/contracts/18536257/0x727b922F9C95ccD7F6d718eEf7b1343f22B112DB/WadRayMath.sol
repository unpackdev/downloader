// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.6;

/// @title WadRayMath.
/// @author Morpho Labs.
/// @custom:contact security@morpho.xyz
/// @notice Optimized version of Aave V3 math library WadRayMath to conduct wad and ray manipulations: https://github.com/aave/aave-v3-core/blob/master/contracts/protocol/libraries/math/WadRayMath.sol
library WadRayMath {
    /// CONSTANTS ///

    // Only direct number constants and references to such constants are supported by inline assembly.
    uint256 internal constant WAD = 1e18;
    uint256 internal constant HALF_WAD = 0.5e18;
    uint256 internal constant WAD_MINUS_ONE = 1e18 - 1;
    uint256 internal constant RAY = 1e27;
    uint256 internal constant HALF_RAY = 0.5e27;
    uint256 internal constant RAY_MINUS_ONE = 1e27 - 1;
    uint256 internal constant RAY_WAD_RATIO = 1e9;
    uint256 internal constant HALF_RAY_WAD_RATIO = 0.5e9;
    uint256 internal constant MAX_UINT256 = 2 ** 256 - 1;
    uint256 internal constant MAX_UINT256_MINUS_HALF_WAD =
        2 ** 256 - 1 - 0.5e18;
    uint256 internal constant MAX_UINT256_MINUS_HALF_RAY =
        2 ** 256 - 1 - 0.5e27;
    uint256 internal constant MAX_UINT256_MINUS_WAD_MINUS_ONE =
        2 ** 256 - 1 - (1e18 - 1);
    uint256 internal constant MAX_UINT256_MINUS_RAY_MINUS_ONE =
        2 ** 256 - 1 - (1e27 - 1);

    /// INTERNAL ///

    /// @dev Executes the ray-based multiplication of 2 numbers, rounded half up.
    /// @param x Ray.
    /// @param y Ray.
    /// @return z The result of x * y, in ray.
    function rayMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // Overflow if
        //     x * y + HALF_RAY > type(uint256).max
        // <=> x * y > type(uint256).max - HALF_RAY
        // <=> y > 0 and x > (type(uint256).max - HALF_RAY) / y
        assembly {
            if mul(y, gt(x, div(MAX_UINT256_MINUS_HALF_RAY, y))) {
                revert(0, 0)
            }

            z := div(add(mul(x, y), HALF_RAY), RAY)
        }
    }

    /// @dev Executes the ray-based multiplication of 2 numbers, rounded down.
    /// @param x Ray.
    /// @param y Ray.
    /// @return z The result of x * y, in ray.
    function rayMulDown(
        uint256 x,
        uint256 y
    ) internal pure returns (uint256 z) {
        // Overflow if
        //     x * y > type(uint256).max
        // <=> y > 0 and x > type(uint256).max / y
        assembly {
            if mul(y, gt(x, div(MAX_UINT256, y))) {
                revert(0, 0)
            }

            z := div(mul(x, y), RAY)
        }
    }

    /// @dev Executes the ray-based multiplication of 2 numbers, rounded up.
    /// @param x Ray.
    /// @param y Wad.
    /// @return z The result of x * y, in ray.
    function rayMulUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // Overflow if
        //     x * y + RAY_MINUS_ONE > type(uint256).max
        // <=> x * y > type(uint256).max - RAY_MINUS_ONE
        // <=> y > 0 and x > (type(uint256).max - RAY_MINUS_ONE) / y
        assembly {
            if mul(y, gt(x, div(MAX_UINT256_MINUS_RAY_MINUS_ONE, y))) {
                revert(0, 0)
            }

            z := div(add(mul(x, y), RAY_MINUS_ONE), RAY)
        }
    }

    /// @dev Executes the ray-based division of 2 numbers, rounded half up.
    /// @param x Ray.
    /// @param y Ray.
    /// @return z The result of x / y, in ray.
    function rayDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // 1. Division by 0 if
        //        y == 0
        // 2. Overflow if
        //        x * RAY + y / 2 > type(uint256).max
        //    <=> x * RAY > type(uint256).max - y / 2
        //    <=> x > (type(uint256).max - y / 2) / RAY
        assembly {
            z := div(y, 2) // Temporary assignment to save gas.

            if iszero(mul(y, iszero(gt(x, div(sub(MAX_UINT256, z), RAY))))) {
                revert(0, 0)
            }

            z := div(add(mul(RAY, x), z), y)
        }
    }

    /// @dev Executes the ray-based multiplication of 2 numbers, rounded up.
    /// @param x Wad.
    /// @param y Wad.
    /// @return z The result of x / y, in ray.
    function rayDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // 1. Division by 0 if
        //        y == 0
        // 2. Overflow if
        //        x * RAY + (y - 1) > type(uint256).max
        //    <=> x * RAY > type(uint256).max - (y - 1)
        //    <=> x > (type(uint256).max - (y - 1)) / RAY
        assembly {
            z := sub(y, 1) // Temporary assignment to save gas.

            if iszero(mul(y, iszero(gt(x, div(sub(MAX_UINT256, z), RAY))))) {
                revert(0, 0)
            }

            z := div(add(mul(RAY, x), z), y)
        }
    }
}
