// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library PackedRange {
    uint256 constant BITS = 128;
    uint256 constant MAX = (1 << BITS) - 1;

    function isWithinRange(uint256 range, uint256 value) internal pure returns (bool) {
        return !((value < (range & MAX)) || (value > (range >> BITS)));
    }
}
