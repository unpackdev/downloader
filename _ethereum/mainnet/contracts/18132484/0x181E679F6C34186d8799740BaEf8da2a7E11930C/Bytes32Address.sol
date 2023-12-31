// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library Bytes32Address {
    function fillLast96Bits(address addressValue) internal pure returns (uint256 value) {
        assembly {
            value := addressValue
        }
    }
}
