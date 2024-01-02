// SPDX-License-Identifier: UNLICENSED
// Zaap.exchange Contracts (NativeWrapper.sol)
pragma solidity ^0.8.19;

import "./IWETH9.sol";

abstract contract NativeWrapper {
    address public immutable NATIVE_TOKEN_ADDRESS = address(0x0000000000000000000000000000000000455448);

    IWETH9 public immutable wETH9;

    constructor(IWETH9 wETH9_) {
        wETH9 = wETH9_;
    }
}
