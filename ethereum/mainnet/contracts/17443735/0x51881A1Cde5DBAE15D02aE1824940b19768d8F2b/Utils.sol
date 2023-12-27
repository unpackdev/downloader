// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

library Utils {
    /// @notice Convert a unsigned integer to bytes.
    /// @param x the uint256 to convert.
    function toBytes(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly {
            mstore(add(b, 32), x)
        }
    }

    /// @notice Remove an element from an array.
    /// @param index Index of the element to remove.
    /// @param array Array to remove from.
    function removeFromArray(uint256 index, uint256[] storage array) internal {
        array[index] = array[array.length - 1];
        array.pop();
    }
}
