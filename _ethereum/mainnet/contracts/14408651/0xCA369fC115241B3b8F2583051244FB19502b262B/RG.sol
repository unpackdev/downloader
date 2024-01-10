// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

abstract contract RG {
    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
}