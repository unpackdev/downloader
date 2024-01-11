// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            unchecked {
                digits++;
                temp /= 10;
            }
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            unchecked {
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation of up to 3 characters.
     */
    function toString3(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }

        string memory buffer;

        if (value > 99) {
            buffer = new string(3);
            assembly {
                mstore8(add(buffer, 0x20), add(div(value, 100), 0x30))
                value := mod(value, 100)
                mstore8(add(buffer, 0x21), add(div(value, 10), 0x30))
                mstore8(add(buffer, 0x22), add(mod(value, 10), 0x30))
            }
        } else if (value > 9) {
            buffer = new string(2);
            assembly {
                mstore8(add(buffer, 0x20), add(div(value, 10), 0x30))
                mstore8(add(buffer, 0x21), add(mod(value, 10), 0x30))
            }
        } else {
            buffer = new string(1);
            assembly {
                mstore8(add(buffer, 0x20), add(value, 0x30))
            }
        }

        return buffer;
    }
}
