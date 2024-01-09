// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Parsable operations.
 */
library Parsable {
    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function safeParseInt(string memory _a)
        internal
        pure
        returns (uint256 _parsedInt)
    {
        return safeParseInt(_a, 0);
    }

    function safeParseInt(string memory _a, uint256 _b)
        internal
        pure
        returns (uint256 _parsedInt)
    {
        bytes memory bresult = bytes(_a);
        uint256 m = 0;
        bool decimals = false;
        for (uint256 i = 0; i < bresult.length; i++) {
            if (
                (uint256(uint8(bresult[i])) >= 48) &&
                (uint256(uint8(bresult[i])) <= 57)
            ) {
                if (decimals) {
                    if (_b == 0) break;
                    else _b--;
                }
                m *= 10;
                m += uint256(uint8(bresult[i])) - 48;
            } else if (uint256(uint8(bresult[i])) == 46) {
                require(!decimals, "more than one decimal in string");
                decimals = true;
            } else {
                revert("Non-numeral character in string!");
            }
        }
        if (_b > 0) {
            m *= 10**_b;
        }
        return m;
    }
}
