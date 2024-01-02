// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library LibMeta {
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}
