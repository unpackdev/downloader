// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

library Abs {
    function abs(int256 x) internal pure returns (uint256) {
        if (x < 0) {
            return uint256(-x);
        } else {
            return uint256(x);
        }
    }
}