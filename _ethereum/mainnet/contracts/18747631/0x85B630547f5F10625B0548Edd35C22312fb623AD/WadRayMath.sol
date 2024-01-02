// SPDX-License-Identifier: GPL-3.0

// A modified version of ds-math library
// Origin: https://github.com/dapphub/ds-math/blob/master/src/math.sol
// Unused methods were removed, errors changed

pragma solidity 0.8.18;
error DS_MATH_ADD_OVERFLOW();
error DS_MATH_MUL_OVERFLOW();

library WadRayMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        if ((z = x + y) < x) revert DS_MATH_ADD_OVERFLOW();
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        if (!(y == 0 || (z = x * y) / y == x)) revert DS_MATH_MUL_OVERFLOW();
    }

    uint256 internal constant WAD = 10 ** 18;
    uint256 internal constant RAY = 10 ** 27;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    //rounds to zero if x*y < RAY / 2
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    //rounds to zero if x*y < WAD / 2
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    //rounds to zero if x*y < RAY / 2
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }
}
