// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

/// @notice Inspired by Andreas Olofsson's Strings library
/// from https://github.com/ethereum/solidity-examples/blob/master/src/strings/Strings.sol
/// which is licensed under MIT license
/// We have rewritten this functionality for solidity 0.8.X
/// and also changed the library to return a bool rather than revert
library Utf8 {

    // Key bytes.
    // http://www.unicode.org/versions/Unicode10.0.0/UnicodeStandard-10.0.pdf
    // Table 3-7, p 126, Well-Formed UTF-8 Byte Sequences

    // Default 80..BF range
    uint256 constant internal DL = 0x80;
    uint256 constant internal DH = 0xBF;

    // Row - number of bytes

    // R1 - 1
    uint256 constant internal B11L = 0x00;
    uint256 constant internal B11H = 0x7F;

    // R2 - 2
    uint256 constant internal B21L = 0xC2;
    uint256 constant internal B21H = 0xDF;

    // R3 - 3
    uint256 constant internal B31 = 0xE0;
    uint256 constant internal B32L = 0xA0;
    uint256 constant internal B32H = 0xBF;

    // R4 - 3
    uint256 constant internal B41L = 0xE1;
    uint256 constant internal B41H = 0xEC;

    // R5 - 3
    uint256 constant internal B51 = 0xED;
    uint256 constant internal B52L = 0x80;
    uint256 constant internal B52H = 0x9F;

    // R6 - 3
    uint256 constant internal B61L = 0xEE;
    uint256 constant internal B61H = 0xEF;

    // R7 - 4
    uint256 constant internal B71 = 0xF0;
    uint256 constant internal B72L = 0x90;
    uint256 constant internal B72H = 0xBF;

    // R8 - 4
    uint256 constant internal B81L = 0xF1;
    uint256 constant internal B81H = 0xF3;

    // R9 - 4
    uint256 constant internal B91 = 0xF4;
    uint256 constant internal B92L = 0x80;
    uint256 constant internal B92H = 0x8F;

    // Returns true if the string is valid UTF-8.
    function isValid(string memory self) internal pure returns (bool valid) {
        valid = true;
        uint256 addr;
        uint256 len;
        assembly {
            addr := add(self, 0x20)
            len := mload(self)
        }
        if (len == 0) {
            return true;
        }
        uint256 bytePos = 0;
        uint256 runeLen;
        while (valid && bytePos < len) {
            (runeLen, valid) = parseRune(addr + bytePos);
            bytePos += runeLen;
        }
        if(bytePos != len) {
            valid = false;
        }
    }

    // Parses a single character, or "rune" stored at address 'bytePos'
    // in memory.
    // Returns the length of the character in bytes.
    function parseRune(uint256 bytePos) internal pure returns (uint256 len, bool valid) {
        valid = true;
        uint256 val;
        assembly {
            val := mload(bytePos)
        }
        val >>= 224; // Remove all but the first four bytes.
        uint256 v0 = val >> 24; // Get first byte.
        if (v0 <= B11H) { // Check a 1 byte character.
            len = 1;
        } else if (B21L <= v0 && v0 <= B21H) { // Check a 2 byte character.
            uint256 v1 = (val & 0x00FF0000) >> 16;
            if (v1 < DL || DH < v1) {
                return (0, false);
            }
            len = 2;
        } else if (v0 == B31) { // Check a 3 byte character in the following three.
            valid = validateWithNextDefault((val & 0x00FFFF00) >> 8, B32L, B32H);
            len = 3;
        } else if (v0 == B51) {
            valid = validateWithNextDefault((val & 0x00FFFF00) >> 8, B52L, B52H);
            len = 3;
        } else if ((B41L <= v0 && v0 <= B41H) || v0 == B61L || v0 == B61H) {
            valid = validateWithNextDefault((val & 0x00FFFF00) >> 8, DL, DH);
            len = 3;
        } else if (v0 == B71) { // Check a 4 byte character in the following three.
            valid = validateWithNextTwoDefault(val & 0x00FFFFFF, B72L, B72H);
            len = 4;
        } else if (B81L <= v0 && v0 <= B81H) {
            valid = validateWithNextTwoDefault(val & 0x00FFFFFF, DL, DH);
            len = 4;
        } else if (v0 == B91) {
            valid = validateWithNextTwoDefault(val & 0x00FFFFFF, B92L, B92H);
            len = 4;
        } else { // If we reach this point, the character is not valid UTF-8
            return (0, false);
        }
    }

    function validateWithNextDefault(uint256 val, uint256 low, uint256 high) internal pure returns(bool) {
        uint256 b = (val & 0xFF00) >> 8;
        if(b < low || high < b) {
            return false;
        }
        b = val & 0x00FF;
        if(b < DL || DH < b) {
            return false;
        }
        return true;
    }

    function validateWithNextTwoDefault(uint256 val, uint256 low, uint256 high) internal pure returns(bool) {
        uint256 b = (val & 0xFF0000) >> 16;
        if(b < low || high < b) {
            return false;
        }
        b = (val & 0x00FF00) >> 8;
        if(b < DL || DH < b) {
            return false;
        }
        b = val & 0x0000FF;
        if (b < DL || DH < b) {
            return false;
        }
        return true;
    }

}

