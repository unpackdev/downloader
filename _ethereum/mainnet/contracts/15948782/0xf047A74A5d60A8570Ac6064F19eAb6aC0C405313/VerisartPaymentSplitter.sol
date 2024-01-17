// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./PaymentSplitter.sol";

// Version: 1.0
contract VerisartPaymentSplitter is PaymentSplitter {
    constructor(address[] memory _payees, uint256[] memory _shares)
        payable
        PaymentSplitter(_payees, _shares)
    {}
}