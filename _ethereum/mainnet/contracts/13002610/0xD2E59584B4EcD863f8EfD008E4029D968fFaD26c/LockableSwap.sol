// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract LockableSwap {
    bool internal inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
}
