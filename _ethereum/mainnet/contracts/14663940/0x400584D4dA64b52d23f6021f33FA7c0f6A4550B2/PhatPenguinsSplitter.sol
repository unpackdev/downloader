// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PaymentSplitter.sol";

contract PhatPenguinsSplitter is PaymentSplitter {
    constructor(address[] memory payees_, uint[] memory shares_) PaymentSplitter(payees_, shares_) {}
}