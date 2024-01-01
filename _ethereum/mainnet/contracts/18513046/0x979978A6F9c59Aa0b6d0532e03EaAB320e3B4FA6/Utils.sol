// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library CommonValidation {
    function _noZeroAddress(address account) internal pure {
        require(account != address(0), "Setting to the zero address");
    }
}

library StringUtils {
    function _bytes32toString(
        bytes32 value
    ) internal pure returns (string memory result) {
        uint8 length = 0;

        while (length < 32 && value[length] != 0) {
            length++;
        }

        assembly {
            result := mload(0x40)
            // new "memory end" including padding (the string isn't larger than 32 bytes)
            mstore(0x40, add(result, 0x40))
            // store length in memory
            mstore(result, length)
            // write actual data
            mstore(add(result, 0x20), value)
        }
    }
}