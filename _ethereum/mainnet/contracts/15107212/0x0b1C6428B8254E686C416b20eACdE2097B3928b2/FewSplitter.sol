// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./PaymentSplitter.sol";

contract FEWSplitter is PaymentSplitter {
    constructor(address[] memory _devs, uint256[] memory _shares) PaymentSplitter(_devs, _shares) {
    }

    // Payout
    function release(address payable account) public override {
        super.release(account);
    }
}