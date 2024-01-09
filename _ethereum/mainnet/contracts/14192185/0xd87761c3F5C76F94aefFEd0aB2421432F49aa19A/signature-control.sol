// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./Strings.sol";

contract SignatureControl {
    function _toEthSignedMessage(bytes memory message) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(message.length), message));
    }

    function _toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(42);
        s[0] = "0";
        s[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
        bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
        bytes1 hi = bytes1(uint8(b) / 16);
        bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
        s[2 * i + 2] = _char(hi);
        s[2 * i + 3] = _char(lo);
        }
        return string(s);
    }

    function _char(bytes1 b) private pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}