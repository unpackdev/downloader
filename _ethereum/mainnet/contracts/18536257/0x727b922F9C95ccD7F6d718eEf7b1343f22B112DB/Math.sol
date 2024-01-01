// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.6;

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := xor(x, mul(xor(x, y), lt(y, x)))
        }
    }
}
