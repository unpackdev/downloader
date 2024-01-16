// SPDX-License-Identifier: MIT
// Unagi Contracts v1.0.0 (UPaymentSplitter.sol)
pragma solidity 0.8.12;

import "./PaymentSplitter.sol";

/**
 * @title UPaymentSplitter
 * @custom:security-contact security@unagi.ch
 */
contract UPaymentSplitter is PaymentSplitter {
    constructor(address[] memory payees, uint256[] memory shares_)
        payable
        PaymentSplitter(payees, shares_)
    {}
}
