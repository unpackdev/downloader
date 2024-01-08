// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PaymentSplitter.sol";

contract SharkCoveRoyalties is PaymentSplitter {
    // Withdrawal addresses
    address t1 = 0x5a6F0489f0bfcD21889D26189C218a455612148F;
    address t2 = 0xA6C045A14127F1D5Dfd3b1aF17823ee54Ef2437d;
    address t3 = 0x100f2EF1D7Ae71fDD792Fd3F2C18ef96C44d916F;
    address t4 = 0xB7edf3Cbb58ecb74BdE6298294c7AAb339F3cE4a;
    address t5 = 0x87a8C74DFA32e09700369584F5dFAD1b5b653E2C;

    address[] addressList = [t1, t2, t3, t4, t5];
    uint256[] shareList = [4500, 2750, 935, 1540, 275];

    constructor()
    PaymentSplitter(addressList, shareList)  {}
}