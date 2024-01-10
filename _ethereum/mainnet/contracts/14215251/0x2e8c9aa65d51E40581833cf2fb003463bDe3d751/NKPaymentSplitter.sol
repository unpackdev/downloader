//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./PaymentSplitter.sol";

contract NKPaymentSplitter is PaymentSplitter {
    constructor(address[] memory payees, uint256[] memory shares_)
        PaymentSplitter(payees, shares_)
    {}
}
