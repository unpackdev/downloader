// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./PaymentSplitter.sol";

contract FreekyPayments is PaymentSplitter {

    constructor (address[] memory _owners, uint256[] memory _shares) PaymentSplitter(_owners, _shares) payable {
    }
}