// contracts/SVGGenerator.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library StringLib {
    
    function intToString(int128 value) internal pure returns (string memory) {
        bool isNegative = false;
        uint256 uintValue = 0;
        if (value < 0) {
            isNegative = true;
            uintValue = uint256(int256(value * -1));
        } else {
            isNegative = false;
            uintValue = uint256(int256(value));
        }
        string memory uString = uintToString(uintValue);
        return isNegative ? concat("-", uString) : uString;
    }

    function uintToString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    function stringToUint(bytes memory b) internal pure returns (uint256) {
        uint result = 0;
        for (uint i = 0; i < b.length; i++) { // c = b[i] was not needed
            uint8 bInU8 = uint8(b[i]);
            if (bInU8 >= 48 /**0 */ && bInU8 <= 57 /**9 */) {
                result = result * 10 + (bInU8 - 48); // bytes and int are not compatible with the operator -.
            }
        }
        return result; // this was missing
}

    function concat(string memory self, string memory other) internal pure returns (string memory) {
        return string(abi.encodePacked(self, other));
    }

    function replace(string memory _str, string memory _pattern, string memory _replacement) internal pure returns (string memory res) {
        
        bytes memory _strBytes = bytes(_str);
        bytes memory pattern = bytes(_pattern);
        bytes memory _replacementBytes = bytes(_replacement);
        require(pattern.length > 0, "pattern's length should L.T. 0");
        uint256 lastHitEndIndexPlus1 = 0;
        for (uint256 i = 0; i < _strBytes.length; i++) {
            //judge if hit
            bool hit = true;
            for (uint256 j = 0; j < pattern.length; j++) {
                if (_strBytes[i + j] != pattern[j]) {
                    hit = false;
                    break;
                }
            }
            
            if (hit) {
                //concat bytes from lastHitEndIndex to i
                res = string(abi.encodePacked(
                    res, substring(_strBytes, lastHitEndIndexPlus1, i), _replacementBytes
                ));
                //update lastHitEndIndex
                lastHitEndIndexPlus1 = i + pattern.length;
                //move i to the tail of the pattern
                i += pattern.length - 1;
            }
        }

        //concat the last part after replace
        res = string(abi.encodePacked(
            res, substring(_strBytes, lastHitEndIndexPlus1, _strBytes.length)
        ));
    }

    function find(bytes memory str, bytes memory pattern) internal pure returns (uint256 index1, uint256 index2, bool exist) {
       uint times = 0;
       for (uint256 i = 0; i < str.length; i++) {
            //judge if hit
            bool hit = true;
            for (uint256 j = 0; j < pattern.length; j++) {
                if (str[i + j] != pattern[j]) {
                    hit = false;
                    break;
                }
            } 
            if (hit == true) {
                if (times == 0) {
                    index1 = i;
                } else if (times == 1) {
                    index2 = i;
                }
                times ++;
                exist = true;
            }
       }
    }

    function substring(bytes memory strBytes, uint startIndex, uint endIndex) internal pure returns (bytes memory) {
        if (endIndex <= startIndex) {
            return bytes("");
        }

        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return result;
    }

    /**
    hsl format is: hsl(60,100%,95%)
     */
    function parseHSL(string memory hsl) internal pure returns (uint256 h, uint256 s, uint256 l) {
        (uint256 posOfFirstComma, uint256 posOfSecondComma, bool _success) = find(bytes(hsl), bytes(","));
        bytes memory hslInBytes = bytes(hsl);
        h = stringToUint(substring(hslInBytes, 4/**hsl(*/, posOfFirstComma));
        s = stringToUint(substring(hslInBytes, posOfFirstComma/**hsl(*/, posOfSecondComma - 1 /**remove %*/));
        l = stringToUint(substring(hslInBytes, posOfSecondComma/**hsl(*/, hslInBytes.length - 2 /**remove %)*/));
    }

    function parseCompressedHSL(bytes memory compressedHSLArray, uint256 index) internal pure returns (uint16, uint16, uint16) {
        uint256 length = compressedHSLArray.length;
        require(length % 8 == 0, "compressedHSLArray.length must be multiplier of 4");
        require(length / 8 > index, "compressedHSLArray.length must be L.T. index");
        
        index = index * 8;
        //for H(0-360)
        uint8 hHightestBit = fromHex(compressedHSLArray[index], compressedHSLArray[index + 1]);
        uint8 hLowestByte = fromHex(compressedHSLArray[index+2], compressedHSLArray[index + 3]);
        uint16 h = hHightestBit == 0 ? hLowestByte : uint16(256) + hLowestByte;
        //for S
        uint16 sLowest7Bits = fromHex(compressedHSLArray[index+4], compressedHSLArray[index + 5]);
        //for L
        uint16 lLowest7Bits = fromHex(compressedHSLArray[index+6], compressedHSLArray[index + 7]);       

        return (h, sLowest7Bits, lLowest7Bits);
    }

    // Convert an hexadecimal string to raw bytes
    function fromHex(bytes1 high, bytes1 low) public pure returns (uint8) {
        return fromHexChar(uint8(high)) * 16 + fromHexChar(uint8(low));
    }

    // Convert an hexadecimal character to their value
    function fromHexChar(uint8 c) public pure returns (uint8) {
        if (bytes1(c) >= bytes1("0") && bytes1(c) <= bytes1("9")) {
            return c - uint8(bytes1("0"));
        } else if (bytes1(c) >= bytes1("a") && bytes1(c) <= bytes1("f")) {
            return 10 + c - uint8(bytes1("a"));
        } else if (bytes1(c) >= bytes1("A") && bytes1(c) <= bytes1("F")) {
            return 10 + c - uint8(bytes1("A"));
        }
    }
}