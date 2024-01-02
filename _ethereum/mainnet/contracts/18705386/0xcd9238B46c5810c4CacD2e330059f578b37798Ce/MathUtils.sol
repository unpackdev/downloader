// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.21;

library MathUtils {

    function _mulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256) {
        if (b == denominator) return a;
        uint256 mulValue = a * b;
        return mulValue / denominator;
    }
}