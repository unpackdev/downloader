// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Color.sol";

abstract contract IColorProvider {
    function totalAmount() public pure virtual returns (uint96);
    function getColor(uint128 id) public pure virtual returns (Color memory);

    bytes16 private constant HEX_ALPHABET = "0123456789ABCDEF";

    function _getColor(
        bytes memory names,
        bytes memory rgbs,
        uint128 index
    ) internal pure returns (Color memory) {
        return Color({
            rgb: string(getColorRgb(rgbs, index)), 
            name: string(getColorName(names, index))
        });
    }

    function getColorName(bytes memory names, uint128 index) internal pure returns (bytes memory) {
        bytes memory result;
        uint256 startIndex = 0;
        uint256 endIndex = 0;

        // Find start index
        for (; startIndex < names.length && index > 0; startIndex++) {
            if (names[startIndex] != "|") continue;

            index--;
        }

        // Find end index. Either next delimeter or terminator.
        for (endIndex = startIndex + 1; endIndex < names.length && names[endIndex] != "|"; endIndex++) {}

        for (; startIndex < endIndex; startIndex++) {
            result = abi.encodePacked(result, names[startIndex]);
        }

        return result;
    }

    function getColorRgb(bytes memory rgbs, uint128 index) internal pure returns (bytes memory) {
        uint256 startIndex = 3 * uint256(index);

        return abi.encodePacked(
            HEX_ALPHABET[(uint8(rgbs[startIndex + 0]) >> 4) & 0xF],
            HEX_ALPHABET[uint8(rgbs[startIndex + 0]) & 0xF],
            HEX_ALPHABET[(uint8(rgbs[startIndex + 1]) >> 4) & 0xF],
            HEX_ALPHABET[uint8(rgbs[startIndex + 1]) & 0xF],
            HEX_ALPHABET[(uint8(rgbs[startIndex + 2]) >> 4) & 0xF],
            HEX_ALPHABET[uint8(rgbs[startIndex + 2]) & 0xF]);
    }
}
