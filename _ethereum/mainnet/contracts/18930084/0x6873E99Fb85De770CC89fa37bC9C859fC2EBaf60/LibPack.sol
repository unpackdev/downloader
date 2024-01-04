// SPDX-License-Identifier: AGPL-3.0-only+VPL
pragma solidity ^0.8.16;

/**
 * @dev Library for packing uint8s in a uint64.
 */
library LibPack {
    /**
     * @dev Returns the `_i`th uint8 in `_x`.
     * @param _x The packed uint64.
     * @param _i The index of the element.
     * @return The element.
     */
    function get(uint64 _x, uint256 _i) internal pure returns (uint8) {
        return uint8(uint256(_x) >> (_i << 3));
    }

    /**
     * @dev Sets the `_i`th element to `_v` and returns the updated packed value.
     * @param _x The packed uint64.
     * @param _i The index of the element.
     * @param _v The value of the element.
     * @return The updated packed value.
     */
    function set(uint64 _x, uint256 _i, uint8 _v) internal pure returns (uint64) {
        uint256 s = _i << 3;
        return uint64(uint256(_x) ^ (((uint256(_x) >> s) ^ uint256(_v)) & 0xff) << s);
    }
}
