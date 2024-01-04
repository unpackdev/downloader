//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.5;

/// @title Strings
/// @notice Utility library for strings
library Strings {
    /// @notice Concat two strings
    /// @param str1 String to concat
    /// @param str2 String to concat
    /// @return result Concated strings
    function appendString(string memory str1, string memory str2) public pure returns (string memory result) {
        return string(abi.encodePacked(str1,str2));
    }
    /// @notice Concat string and number
    /// @param str String to concat
    /// @param i Number to concat
    /// @return result Concated string and number
    function appendNumber(string memory str, uint i) public pure returns (string memory result) {
        return string(abi.encodePacked(str,i+uint(48)));
    }
}
