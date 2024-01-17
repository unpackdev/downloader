// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/// @title Utility function for developing smart contract
/// @author LiquidX
/// @notice You could use function in this smart contract as 
///         a helper to do menial task
/// @dev All function in this contract has generic purposes 
///      like converting integer to string, converting an array, etc.

contract AmvUtils {
    /// @dev Convert integer into string
    /// @param value Integer value that would be converted into string
    function intToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /// @dev Convert integer into a single-element array
    /// @param element Unsigned integer that would be inserted to array
    function singletonArray(uint256 element)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}
