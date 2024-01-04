// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./DSMath.sol";

function _stringToBytes32(string memory str) pure returns (bytes32 result) {
    require(bytes(str).length != 0, "string-empty");
    assembly {
        result := mload(add(str, 32))
    }
}

function _convertTo18(uint256 _dec, uint256 _amt) pure returns (uint256 amt) {
    amt = _mul(_amt, 10**(18 - _dec));
}
