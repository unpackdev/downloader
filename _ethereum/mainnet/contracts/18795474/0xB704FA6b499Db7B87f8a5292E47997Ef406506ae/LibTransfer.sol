// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
/* Gambulls LibTransfer 2023 */

library LibTransfer {
    function transferPayableAmount(address to, uint256 value) internal {
        (bool success,) = to.call{ value: value }("");
        require(success, "transfer failed");
    }
}
