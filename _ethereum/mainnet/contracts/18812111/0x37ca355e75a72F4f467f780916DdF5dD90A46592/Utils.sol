// SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

import "./Interface.sol";

/**
 * @title - dev3.eth : Utils
 * @author - sshmatrix.eth, freetib.eth
 * @notice - https://dev3.eth.limo
 * https://github.com/namesys-eth/dev3-eth-resolver
 */
library Utils {
    bytes16 internal constant b16 = "0123456789abcdef";
    bytes16 internal constant B16 = "0123456789ABCDEF";

    /**
     * Convert address to check-summed address string
     * @param _addr - Address
     */
    function toChecksumAddress(address _addr) internal pure returns (string memory) {
        if (_addr == address(0)) {
            return "0x0000000000000000000000000000000000000000";
        }
        bytes memory _buffer = abi.encodePacked(_addr);
        bytes memory result = new bytes(40);
        bytes32 hash = keccak256(abi.encodePacked(bytesToHexString(_buffer)));
        uint256 d;
        uint256 r;
        unchecked {
            for (uint256 i = 0; i < 20; i++) {
                d = uint8(_buffer[i]) / 16;
                r = uint8(_buffer[i]) % 16;
                result[i * 2] = uint8(hash[i]) / 16 > 7 ? B16[d] : b16[d];
                result[i * 2 + 1] = uint8(hash[i]) % 16 > 7 ? B16[r] : b16[r];
            }
        }
        return string.concat("0x", string(result));
    }

    /**
     * Convert bytes to hexadecimal string
     * @param _input - Bytes input to convert
     */
    function bytesToHexString(bytes memory _input) internal pure returns (string memory) {
        unchecked {
            uint256 len = _input.length;
            bytes memory result = new bytes(len * 2);
            uint8 _b;
            for (uint256 i = 0; i < len; i++) {
                _b = uint8(_input[i]);
                result[i * 2] = b16[_b / 16];
                result[(i * 2) + 1] = b16[_b % 16];
            }
            return string(result);
        }
    }

    /**
     * Convert uint to string format
     * @param _input - Uint Numbers to convert
     */
    function uintToString(uint256 _input) internal pure returns (string memory) {
        if (_input == 0) {
            return "0";
        }
        uint256 len;
        unchecked {
            len = log10(_input) + 1;
            bytes memory buffer = new bytes(len);
            while (_input > 0) {
                buffer[--len] = bytes1(uint8(48 + (_input % 10)));
                _input /= 10;
            }
            return string(buffer);
        }
    }

    /**
     * log10 of uint
     * @param _input - number
     * @dev https://github.com/OpenZeppelin/openzeppelin-contracts/blob/cffb2f1ddcd87efd68effc92cfd336c5145acabd/contracts/utils/math/Math.sol#L327
     */
    function log10(uint256 _input) internal pure returns (uint256 result) {
        unchecked {
            if (_input >= 1e64) {
                _input /= 1e64;
                result += 64;
            }
            if (_input >= 1e32) {
                _input /= 1e32;
                result += 32;
            }
            if (_input >= 1e16) {
                _input /= 1e16;
                result += 16;
            }
            if (_input >= 1e8) {
                _input /= 1e8;
                result += 8;
            }
            if (_input >= 10000) {
                _input /= 10000;
                result += 4;
            }
            if (_input >= 100) {
                _input /= 100;
                result += 2;
            }
            if (_input >= 10) {
                ++result;
            }
        }
    }
}
