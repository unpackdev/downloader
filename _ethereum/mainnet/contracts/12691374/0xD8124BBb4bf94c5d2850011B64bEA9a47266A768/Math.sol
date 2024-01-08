// SPDX-License-Identifier: GNU
pragma solidity ^0.8.1;

library Math {

    function abs(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a > b) ? a - b : b - a;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
