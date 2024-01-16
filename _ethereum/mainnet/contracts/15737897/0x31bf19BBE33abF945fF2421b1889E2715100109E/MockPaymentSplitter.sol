pragma solidity =0.8.9;

import "./PaymentSplitter.sol";

contract MockPaymentSplitter is PaymentSplitter {
    constructor(address[] memory payees, uint256[] memory shares_) payable
    PaymentSplitter(payees, shares_) {}
}