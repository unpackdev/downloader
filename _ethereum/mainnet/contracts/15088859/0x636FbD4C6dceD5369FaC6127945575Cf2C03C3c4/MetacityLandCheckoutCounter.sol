// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ETHAndERC20CheckoutCounter.sol";

contract MetacityLandCheckoutCounter is ETHAndERC20CheckoutCounter {
    constructor() ETHAndERC20CheckoutCounter() {
    }
}