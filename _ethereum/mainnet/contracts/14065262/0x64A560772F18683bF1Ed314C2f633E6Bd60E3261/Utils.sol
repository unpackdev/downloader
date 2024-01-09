// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./base64.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";
import "./Strings.sol";

library Utils {
    bytes16 internal constant ALPHABET = '0123456789abcdef';
    
    function timestampToString(uint timestamp) internal pure returns (string memory) {
        (uint year, uint month, uint day, uint hour, uint minute, uint second) = BokkyPooBahsDateTimeLibrary.timestampToDateTime(timestamp);
        
        return string(abi.encodePacked(
          Strings.toString(year), "-",
          zeroPadTwoDigits(month), "-",
          zeroPadTwoDigits(day)
        ));
    }
    
    function zeroPadTwoDigits(uint number) internal pure returns (string memory) {
        string memory numberString = Strings.toString(number);
        
        if (bytes(numberString).length < 2) {
            numberString = string(abi.encodePacked("0", numberString));
        }
        
        return numberString;
    }
    
    function addressToString(address addr)
        internal
        pure
        returns (string memory)
    {
        return Strings.toHexString(uint160(addr), 20);
    }
    
    function toHexStringNoPrefix(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = buffer.length; i > 0; i--) {
            buffer[i - 1] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }
    
    function toHexColor(uint24 value) internal pure returns (string memory) {
      return toHexStringNoPrefix(value, 3);
    }
    
    // You don't see a lot of HTML escaping in smart contracts these days, and for good reason!
    // This approach is adapted from the escapeQuotes() method in Uniswap's NFTDescriptor.sol
    // https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/NFTDescriptor.sol#L85
    //
    // The conceptually-simpler version would be to go through the input string one time and
    // abi.encodePacked() each byte or escape sequence on to the output. This approach
    // is more complicated for the computer though and isn't so great with long strings.
    //
    // Notably I am not escaping quotes. Based on my understanding you only need to escape quotes
    // if the input string might be used in an HTML attribute, but still this is a dice roll.
    // HTML is kind of a beautiful format for how simple it is to escape! Just (if I'm right) three
    // special characters to worry about. Compare this to JSON where you have to worry about
    // escaping, for example, the iconic bell character (U+0007)
    //
    // However this does not make HTML easier to write by hand because you have to remember
    // that " & " is not valid! If you write an amperstand you have to follow through
    // with the escape sequence or you risk your thing breaking in a weird way eventually.
    function escapeHTML(string memory input)
        internal
        pure
        returns (string memory)
    {
        bytes memory inputBytes = bytes(input);
        uint extraCharsNeeded = 0;
        
        for (uint i = 0; i < inputBytes.length; i++) {
            bytes1 currentByte = inputBytes[i];
            
            if (currentByte == "&") {
                extraCharsNeeded += 4;
            } else if (currentByte == "<") {
                extraCharsNeeded += 3;
            } else if (currentByte == ">") {
                extraCharsNeeded += 3;
            }
        }
        
        if (extraCharsNeeded > 0) {
            bytes memory escapedBytes = new bytes(
                inputBytes.length + extraCharsNeeded
            );
            
            uint256 index;
            
            for (uint i = 0; i < inputBytes.length; i++) {
                if (inputBytes[i] == "&") {
                    escapedBytes[index++] = "&";
                    escapedBytes[index++] = "a";
                    escapedBytes[index++] = "m";
                    escapedBytes[index++] = "p";
                    escapedBytes[index++] = ";";
                } else if (inputBytes[i] == "<") {
                    escapedBytes[index++] = "&";
                    escapedBytes[index++] = "l";
                    escapedBytes[index++] = "t";
                    escapedBytes[index++] = ";";
                } else if (inputBytes[i] == ">") {
                    escapedBytes[index++] = "&";
                    escapedBytes[index++] = "g";
                    escapedBytes[index++] = "t";
                    escapedBytes[index++] = ";";
                } else {
                    escapedBytes[index++] = inputBytes[i];
                }
            }
            return string(escapedBytes);
        }
        
        return input;
    }
    
    function hashText(string memory text) public pure returns (string memory) {
        return Strings.toHexString(uint256(keccak256(bytes(text))), 32);
    }
}