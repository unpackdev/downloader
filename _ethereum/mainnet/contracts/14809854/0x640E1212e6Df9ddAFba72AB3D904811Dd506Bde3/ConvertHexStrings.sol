// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

library ConvertHexStrings {
    /**
     * @dev Convert address to string
     * @param account - account hex address
     * @return string - hex string
     */
    function addressToString(address account) internal pure returns (string memory) {
        return toString(abi.encodePacked(account));
    }

    /**
     * @dev convert bytes data to string
     * @param data - data is type of bytes
     * @return string - string of alphabet
     */

    function toString(bytes memory data) internal pure returns (string memory) {
        bytes memory alphabet = '0123456789abcdef';

        bytes memory str = new bytes(2 + data.length * 2);
        uint256 dataLength = data.length;
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < dataLength; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
}
