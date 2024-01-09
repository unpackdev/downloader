//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// small helpers for strings
library StringHelpers {
    /// @notice Checks if the string is valid (0-9a-zA-Z,- ) with no leading, trailing or consecutives spaces
    ///         This function is a modified version of the one in the Hashmasks contract
    /// @param str the name to validate
    /// @return if the name is valid
    function isNameValid(string memory str) internal pure returns (bool) {
        bytes memory strBytes = bytes(str);
        if (strBytes.length < 1) return false;
        if (strBytes.length > 32) return false; // Cannot be longer than 32 characters

        uint8 charCode;
        for (uint256 i; i < strBytes.length; i++) {
            charCode = uint8(strBytes[i]);

            if (
                !(charCode >= 97 && charCode <= 122) && // a - z
                !(charCode >= 65 && charCode <= 90) && // A - Z
                !(charCode >= 48 && charCode <= 57) // 0 - 9
            ) {
                return false;
            }
        }

        return true;
    }

    /// @notice Slugify a name (tolower and replace all non 0-9az by -)
    /// @param str the string to keyIfy
    /// @return the key
    function slugify(string memory str) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory lowerCase = new bytes(strBytes.length);
        uint8 charCode;
        bytes1 char;
        for (uint256 i; i < strBytes.length; i++) {
            char = strBytes[i];
            charCode = uint8(char);

            // if 0-9, a-z use the character
            if (
                (charCode >= 48 && charCode <= 57) ||
                (charCode >= 97 && charCode <= 122)
            ) {
                lowerCase[i] = char;
            } else if (charCode >= 65 && charCode <= 90) {
                // if A-Z, use lowercase
                lowerCase[i] = bytes1(charCode + 32);
            } else {
                // for all others, use a -
                lowerCase[i] = 0x2D;
            }
        }

        return string(lowerCase);
    }
}
