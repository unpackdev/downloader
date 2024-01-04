// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Bytes32 {
    function toBytes32(string memory source) internal pure returns (bytes32 result) {
        if (bytes(source).length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }
}
