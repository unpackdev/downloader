// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

abstract contract Value {
    error NonZeroAddress();

    modifier nonZA(address sender) {
        if (address(0) == sender) revert NonZeroAddress();
        _;
    }
}
