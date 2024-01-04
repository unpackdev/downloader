// SPDX-License-Identifier: None
pragma solidity >=0.7.5;

/// @title Strings
/// @notice Utility library for strings
contract Strings {
    /// @notice Concat two strings
    /// @param str1 String to concat
    /// @param str2 String to concat
    /// @return result Concatenated strings
    function appendString(string memory str1, string memory str2) public pure returns (string memory result) {
        return string(abi.encodePacked(str1, str2));
    }

    /// @notice Concat number and string
    /// @param i Number to concat
    /// @param str String to concat
    /// @return result Concatenated string and number
    function prependNumber(uint256 i, string memory str) public pure returns (string memory result) {
        if (i == 0) {
            return string(abi.encodePacked("0", str));
        }

        return prependNumber(i / 10, string(abi.encodePacked(uint8((i % 10) + 48), str)));
    }
}
