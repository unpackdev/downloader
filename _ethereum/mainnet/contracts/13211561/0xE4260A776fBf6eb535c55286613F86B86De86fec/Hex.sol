// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library Hex {

    function encode(bytes1 b) internal pure returns (string memory) {
        uint8 i = uint8(b);
        return string(
            abi.encodePacked(
                _encodeLowNibble(i >> 4),
                _encodeLowNibble(i)
            )
        );
    }

    function _encodeLowNibble(uint8 val) private pure returns (uint8) {
        uint8 nibble = val & 0xf;
        if (nibble > 9) {
            // encode as upper case character A..F
            return nibble + 55;
        } else {
            // encode as numeric digit 0..9
            return nibble + 48;
        }
    }
}