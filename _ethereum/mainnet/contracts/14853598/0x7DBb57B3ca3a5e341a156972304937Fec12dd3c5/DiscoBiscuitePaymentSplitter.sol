// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PaymentSplitter.sol";

contract DiscoBiscuitePaymentSplitter is PaymentSplitter {
    address[] payeesArray = [0xF499007817F71b1A689BAbdcE0470DC76915B2D7,0x2ee90845880C4657D85d047146b5f1295dc81BCE,0xC6B7a6C4b1979e0B750D80b3De895aa16E90af4e];
    uint256[] sharesArray = [75, 20, 5];

    constructor() 
        PaymentSplitter(payeesArray, sharesArray) {
    }
}