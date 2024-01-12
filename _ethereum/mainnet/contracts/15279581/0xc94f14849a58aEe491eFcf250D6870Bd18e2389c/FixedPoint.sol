// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

library FixedPoint {
    uint256 internal constant ONE = 1e18; // 18 decimal places

    function mulUp(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            uint256 product = a * b;
            require(a == 0 || product / a == b, "overflow");

            if (product == 0) {
                return 0;
            } else {
                // The traditional divUp formula is:
                // divUp(x, y) := (x + y - 1) / y
                // To avoid intermediate overflow in the addition, we distribute the division and get:
                // divUp(x, y) := (x - 1) / y + 1
                // Note that this requires x != 0, which we already tested for.

                return ((product - 1) / ONE) + 1;
            }
        }
    }
}
