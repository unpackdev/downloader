// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

library Packed64 {
    function read64(uint256 packed, uint256 index)
    internal
    pure
    returns (uint64 value)
    {
        assembly {
            value := shl(mul(index, 64), packed)
            value := shr(192, value)
        }
    }

    function write64(
        uint256 packed,
        uint256 index,
        uint64 newValue
    ) internal pure returns (uint256 newPacked) {
        assembly {
            let shiftedValue := shl(mul(sub(3, index), 64), newValue)
            newPacked := or(shiftedValue, packed)
        }
    }
}
