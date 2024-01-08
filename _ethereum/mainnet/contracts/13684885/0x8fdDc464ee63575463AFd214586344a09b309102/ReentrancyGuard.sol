//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

abstract contract ReentrancyGuard {
    uint8 private _unlocked = 1;

    modifier nonReentrant() {
        require(_unlocked == 1, "ReentrancyGuard: reentrant call");
        _unlocked = 0;
        _;
        _unlocked = 1;
    }
}
