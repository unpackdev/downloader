// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

library BpLibrary {
    // Inverse basis point.
    uint256 public constant INVERSE_BASIS_POINT = 10000;

    function bp(uint256 value, uint256 bpValue)
        internal
        pure
        returns (uint256)
    {
        return (value * bpValue) / INVERSE_BASIS_POINT;
    }
}
