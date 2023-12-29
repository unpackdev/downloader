// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.23;

uint256 constant FORTUNE_MIN = 1;
uint256 constant FORTUNE_MAX = 100;
uint256 constant FORTUNE_COUNT = 9;
uint256 constant FORTUNE_MASK = 0xFF;
uint256 constant FORTUNE_ELEMENTS = 10;
uint256 constant FORTUNE_TITLES = 25;
uint256 constant FORTUNE_CARD_ELEMENTS = 5;

uint256 constant CURSE_ELEMENTS = 7;
uint256 constant CURSE_OFFSET = 72;
uint256 constant CURSED_CARD_ELEMENTS = 5;

uint256 constant MIN_DATE = 1;
uint256 constant MAX_DATE = 1000000;

library Fortune {

    uint256 private constant DEADLY_MAX = 7;
    uint256 private constant COMMANDS_MAX = 50;

    uint256 private constant MASK_UINT8_1 = 0xFF0000000000;
    uint256 private constant MASK_UINT8_2 = 0x00FF00000000;
    uint256 private constant MASK_UINT8_3 = 0x0000FF000000;
    uint256 private constant MASK_UINT8_4 = 0x000000FF0000;
    uint256 private constant MASK_UINT8_5 = 0x00000000FF00;
    uint256 private constant MASK_UINT8_6 = 0x0000000000FF;

    uint256 private constant MASK_UINT16_1 = 0xFFFF00000000;
    uint256 private constant MASK_UINT16_2 = 0x00FFFF000000;
    uint256 private constant MASK_UINT16_3 = 0x0000FFFF0000;
    uint256 private constant MASK_UINT16_4 = 0x000000FFFF00;
    uint256 private constant MASK_UINT16_5 = 0x00000000FFFF;

    function titleIndex(
        uint256 fortune
    ) internal pure returns(uint256) {
        unchecked { return ((_at(fortune, 0)) * _at(fortune, 3) * _at(fortune, 6)) % FORTUNE_TITLES; }
    }

    function colorIndex(
        uint256 fortune
    ) internal pure returns(uint256) {
        unchecked { return (_at(fortune, 0) + _at(fortune, 1) + _at(fortune, 2)) % FORTUNE_MAX; }
    }

    function animalIndex(
        uint256 fortune
    ) internal pure returns(uint256) {
        unchecked { return (_at(fortune, 3) + _at(fortune, 4) + _at(fortune, 5)) % FORTUNE_MAX; }
    }

    function charmIndex(
        uint256 fortune
    ) internal pure returns(uint256) {
        unchecked { return (_at(fortune, 6) + _at(fortune, 7) + _at(fortune, 8)) % FORTUNE_MAX; }
    }

    function cursedIndex(
        uint256 fortune
    ) internal pure returns(uint256) {
        unchecked { return (_value(fortune, 1) + _value(fortune, 4) + _value(fortune, 7)) % FORTUNE_MAX; }
    }

    function deadlyIndex(
        uint256 fortune
    ) internal pure returns(uint256) {
        unchecked { return ((_at(fortune, 2)) + _at(fortune, 5) + _at(fortune, 8)) % DEADLY_MAX; }
    }

    function dateIndex(
        uint256 fortune
    ) internal pure returns(uint256) {
        unchecked {
            return ((_value(fortune, 1) * _value(fortune, 4) * _value(fortune, 7) + uint16(fortune)) % MAX_DATE) + MIN_DATE;
        }
    }

    function cmdIndex(
        uint256 fortune,
        uint256 offset
    ) internal pure returns (uint256) {
        return (_value(fortune, offset) + offset) % COMMANDS_MAX;
    }

    uint256 private constant CHECK_69_1 = 0x450000000000;
    uint256 private constant CHECK_69_2 = 0x004500000000;
    uint256 private constant CHECK_69_3 = 0x000045000000;
    uint256 private constant CHECK_69_4 = 0x000000450000;
    uint256 private constant CHECK_69_5 = 0x000000004500;
    uint256 private constant CHECK_69_6 = 0x000000000045;

    uint256 private constant CHECK_420_1 = 0x041400000000;
    uint256 private constant CHECK_420_2 = 0x000414000000;
    uint256 private constant CHECK_420_3 = 0x000004140000;
    uint256 private constant CHECK_420_4 = 0x000000041400;
    uint256 private constant CHECK_420_5 = 0x000000000414;

    function isCosmic(
        uint256 fortune
    ) internal pure returns (bool) {
        if (fortune == 0) return true;
        return ((
            // Check for 69 (0x45) at any position
            ((fortune & MASK_UINT8_1) == CHECK_69_1) ||
            ((fortune & MASK_UINT8_2) == CHECK_69_2) ||
            ((fortune & MASK_UINT8_3) == CHECK_69_3) ||
            ((fortune & MASK_UINT8_4) == CHECK_69_4) ||
            ((fortune & MASK_UINT8_5) == CHECK_69_5) ||
            ((fortune & MASK_UINT8_6) == CHECK_69_6)
        ) && (
            // Check for the sequence 4, 20 (0x0414) at any position
            ((fortune & MASK_UINT16_1) == CHECK_420_1) ||
            ((fortune & MASK_UINT16_2) == CHECK_420_2) ||
            ((fortune & MASK_UINT16_3) == CHECK_420_3) ||
            ((fortune & MASK_UINT16_4) == CHECK_420_4) ||
            ((fortune & MASK_UINT16_5) == CHECK_420_5)
        ));
    }

    uint256 private constant CHECK_13_1 = 0x0D0000000000;
    uint256 private constant CHECK_13_2 = 0x000D00000000;
    uint256 private constant CHECK_13_3 = 0x00000D000000;
    uint256 private constant CHECK_13_4 = 0x0000000D0000;
    uint256 private constant CHECK_13_5 = 0x000000000D00;
    uint256 private constant CHECK_13_6 = 0x00000000000D;

    uint256 private constant CHECK_666_1 = 0x064200000000;
    uint256 private constant CHECK_666_2 = 0x000642000000;
    uint256 private constant CHECK_666_3 = 0x000006420000;
    uint256 private constant CHECK_666_4 = 0x000000064200;
    uint256 private constant CHECK_666_5 = 0x000000000642;

    function isInfernal(
        uint256 fortune
    ) internal pure returns (bool) {
        return ((
            // Check for 13 (0x0D) at any position
            ((fortune & MASK_UINT8_1) == CHECK_13_1) ||
            ((fortune & MASK_UINT8_2) == CHECK_13_2) ||
            ((fortune & MASK_UINT8_3) == CHECK_13_3) ||
            ((fortune & MASK_UINT8_4) == CHECK_13_4) ||
            ((fortune & MASK_UINT8_5) == CHECK_13_5) ||
            ((fortune & MASK_UINT8_6) == CHECK_13_6)
        ) && (
            // Check for the sequence 6, 66 (0x0642) at any position
            ((fortune & MASK_UINT16_1) == CHECK_666_1) ||
            ((fortune & MASK_UINT16_2) == CHECK_666_2) ||
            ((fortune & MASK_UINT16_3) == CHECK_666_3) ||
            ((fortune & MASK_UINT16_4) == CHECK_666_4) ||
            ((fortune & MASK_UINT16_5) == CHECK_666_5)
        ));
    }

    function scaleToRange(
        int256 number,
        int256 min,
        int256 max,
        int256 newMin,
        int256 newMax
    ) internal pure returns (int256) {
        unchecked {
            return (number - min) * (newMax - newMin) / (max - min) + newMin;
        }
    }

    function scaleToRange(
        uint256 number,
        uint256 min,
        uint256 max,
        uint256 newMin,
        uint256 newMax
    ) internal pure returns (uint256) {
        unchecked {
            return (number - min) * (newMax - newMin) / (max - min) + newMin;
        }
    }

    function avgValue(
        uint256 fortune,
        uint256 index
    ) internal pure returns (uint256) {
       return (_value(fortune, index) + _value(fortune, index+1) + _value(fortune, index+2))/3;
    }

    function value(
        uint256 fortune,
        uint256 index
    ) internal pure returns(uint256) {
        return _value(fortune, index);
    }

    function at(
        uint256 fortune,
        uint256 index
    ) internal pure returns(uint256) {
        return _at(fortune, index);
    }

    function _value(
        uint256 fortune,
        uint256 index
    ) private pure returns(uint256) {
        unchecked { return _at(fortune, index) + 1; }
    }

    function _at(
        uint256 fortune,
        uint256 index
    ) private pure returns(uint256) {
        return (fortune >> (index * 8) & FORTUNE_MASK);
    }
}
