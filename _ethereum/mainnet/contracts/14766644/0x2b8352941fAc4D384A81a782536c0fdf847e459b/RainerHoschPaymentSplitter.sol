// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PaymentSplitter.sol";

contract RainerHoschPaymentSplitter is PaymentSplitter {
    address[] payeesArray = [0xFEC0A8dAab6563B4B4827929a927c4da5650634B,0x28d2bFE61cA1497A87edB80d77605D9d50f2B786,0x0471ACE0867b81125bD8b20FC6b0b20D634859fA];
    uint256[] sharesArray = [50, 25, 25];

    constructor() 
        PaymentSplitter(payeesArray, sharesArray) {
    }
}