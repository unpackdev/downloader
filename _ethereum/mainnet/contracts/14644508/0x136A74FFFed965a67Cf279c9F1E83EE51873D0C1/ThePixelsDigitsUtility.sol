// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;

import "./Strings.sol";

contract ThePixelsDigitsUtility {
    using Strings for uint256;

    function _replacedDigits(
        uint256 value,
        uint256 length,
        uint256 beginIndex,
        uint256 endIndex,
        uint256 replaceValue
    ) internal pure returns (uint256) {
        require(endIndex > beginIndex, "Indexes are invalid");

        unchecked {
            uint256 maxReplaceValue = uint256(10**(endIndex - beginIndex) - 1);
            require(
                replaceValue <= maxReplaceValue,
                "Replace value is too big"
            );

            uint256 minReplaceValue = uint256(10**(endIndex - beginIndex - 1));
            require(
                replaceValue >= minReplaceValue,
                "Replace value is too small"
            );

            if (value == 0) {
                value = 1;
            }

            if (beginIndex < length && endIndex < length) {
                uint256 left = (value / (10**(length - beginIndex))) *
                    (10**(length - beginIndex));
                uint256 middle = replaceValue * (10**(length - endIndex));
                uint256 leftFromEndIndex = uint256(
                    (value / (10**(length - endIndex))) *
                        (10**(length - endIndex))
                );
                uint256 right = value - leftFromEndIndex;
                return left + middle + right;
            } else if (beginIndex >= length && endIndex >= length) {
                uint256 left = value * (10**(endIndex - length));
                return left + replaceValue;
            } else if (beginIndex < length && endIndex >= length) {
                uint256 left = (value / (10**(length - beginIndex))) *
                    (10**(endIndex - beginIndex));
                return left + replaceValue;
            }
        }

        return value;
    }

    function _digitsAt(
        uint256 value,
        uint256 length,
        uint256 beginIndex,
        uint256 endIndex
    ) internal pure returns (uint256) {
        require(endIndex > beginIndex, "Indexes are invalid");

        unchecked {
            if (length == 0) {
                length = 1;
            }

            if (beginIndex < length && endIndex <= length) {
                uint256 left = (value / (10**(length - beginIndex))) *
                    (10**(length - beginIndex));
                uint256 valueWithoutLeft = value - left;
                return valueWithoutLeft / (10**(length - endIndex));
            } else if (beginIndex >= length && endIndex >= length) {
                return 0;
            }
        }

        return value;
    }

    function _digitOf(uint256 value) internal pure returns (uint256) {
        return bytes(value.toString()).length;
    }
}
