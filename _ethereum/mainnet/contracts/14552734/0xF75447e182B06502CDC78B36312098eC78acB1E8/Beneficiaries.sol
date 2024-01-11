//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "./PaymentSplitter.sol";

contract Beneficiaries is PaymentSplitter{
    constructor (address[] memory _payees, uint[] memory _shares) PaymentSplitter(_payees, _shares) payable {}
}