// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Admin {
    function isOwnerOrAdmin(address owner, mapping(address => bool) storage admins, address account) internal view returns (bool) {
        return account == owner || admins[account];
    }
}
