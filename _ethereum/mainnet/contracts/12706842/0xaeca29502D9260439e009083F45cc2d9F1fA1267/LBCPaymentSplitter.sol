//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.0 <0.8.0;

import "./PaymentSplitter.sol";

contract LBCPaymentSplitter is PaymentSplitter {
    
    constructor() PaymentSplitter(
        0x678DaaAdb798AEFC47Ca036858e3B25698b3c24C, // _owner_wallet,
        0x05229d7A6218CE56Ef1386d634f1953A463aA065, // _creator_wallet,
        10                                          // _creator_fee,
    ){}
}