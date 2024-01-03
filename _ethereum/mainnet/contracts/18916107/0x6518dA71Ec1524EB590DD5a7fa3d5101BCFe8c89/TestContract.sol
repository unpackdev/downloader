// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract UshTest {
    address public immutable unshETHAddress;

    constructor(address _unshETHAddress) {
        unshETHAddress = _unshETHAddress;
    }
}
