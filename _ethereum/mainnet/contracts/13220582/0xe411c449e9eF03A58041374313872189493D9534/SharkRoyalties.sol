// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PaymentSplitter.sol";

contract SharkRoyalties is PaymentSplitter {
    // Withdrawal addresses
    address t1 = 0x100f2EF1D7Ae71fDD792Fd3F2C18ef96C44d916F;
    address t2 = 0xda73C4DFa2F04B189A7f8EafB586501b4D0B73dC;

    address[] addressList = [t1, t2];
    uint256[] shareList = [65, 35];

    constructor()
    PaymentSplitter(addressList, shareList)  {}
}