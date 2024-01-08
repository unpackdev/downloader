// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PaymentSplitter.sol";

contract OpenSeaSecondarySplitter is PaymentSplitter {
    constructor(address[] memory payees, uint256[] memory shares) PaymentSplitter(payees, shares) {}

    function getAvailablePayment(address account) 
    external view returns (uint256) {
        uint256 totalReceived = address(this).balance + _totalReleased;
        return totalReceived * _shares[account] / _totalShares - _released[account];
    }
} 