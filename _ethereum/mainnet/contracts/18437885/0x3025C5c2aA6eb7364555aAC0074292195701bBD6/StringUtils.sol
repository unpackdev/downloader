// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @dev String operations.
 */
library StringUtils {
    /**
     * @dev Pads on the left of a `string` as many `value` character as `amount` quantity.
     */
    function padStart(string memory baseString, uint256 amount, string memory value) internal pure returns (string memory) {
        for (uint256 i = bytes(baseString).length; i < amount; i++) {
            baseString = string(abi.encodePacked(value, baseString));
        }
        return baseString;
    }
}
