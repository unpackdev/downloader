//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "./Strings.sol";

library StringLib {
    bytes16 private constant _HEX_SYMBOLS = '0123456789abcdef';

    function toBalanceString(uint256 balance, uint256 decimals)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    StringLib.toString(balance / 1e18),
                    '.',
                    StringLib.toFixedLengthString(
                        (balance % 1e18) / (10**(18 - decimals)),
                        decimals
                    )
                )
            );
    }

    function toFixedLengthString(uint256 value, uint256 digits)
        internal
        pure
        returns (string memory)
    {
        require(value <= 10**digits, 'Value cannot be in digits');

        bytes memory buffer = new bytes(digits);
        for (uint8 i = 0; i < digits; i++) {
            buffer[digits - 1 - i] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        return Strings.toString(value);
    }

    function toHex(uint256 value) internal pure returns (string memory) {
        return Strings.toHexString(value);
    }

    function toHex(uint256 value, uint256 length) internal pure returns (string memory) {
        return Strings.toHexString(value, length);
    }

    // TODO: Fix this

    function toHexColor(uint256 value) internal pure returns (string memory) {
        bytes memory buffer = new bytes(8);
        buffer[0] = _HEX_SYMBOLS[(value >> 28) & 0xf];
        buffer[1] = _HEX_SYMBOLS[(value >> 24) & 0xf];
        buffer[2] = _HEX_SYMBOLS[(value >> 20) & 0xf];
        buffer[3] = _HEX_SYMBOLS[(value >> 16) & 0xf];
        buffer[4] = _HEX_SYMBOLS[(value >> 12) & 0xf];
        buffer[5] = _HEX_SYMBOLS[(value >> 8) & 0xf];
        buffer[6] = _HEX_SYMBOLS[(value >> 4) & 0xf];
        buffer[7] = _HEX_SYMBOLS[(value) & 0xf];
        return string(buffer);
    }
}
