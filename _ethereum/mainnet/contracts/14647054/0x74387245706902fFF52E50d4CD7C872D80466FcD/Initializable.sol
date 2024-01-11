// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Initializable {

    bool public initialized = false;

    modifier needInit() {
        require(initialized, "Contract not init.");
        _;
    }
}