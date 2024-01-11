// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PaymentSplitter.sol";

contract GoblinSlayerTreasury is PaymentSplitter {

    address[] private _payees = [
        0x0832427c23601967911d189467A78CBaB179225B,
        0xb00356d2069dbb07a0bB2983bb11c29300e63116,
        0x0cB801a4325F60A6287036E90dBB93d41076C1CA,
        0x585508e8e4A0D94451A44e96c15f004a3b2d4B2c
    ];

    uint256[] private _shares = [
        25000,
        25000,
        25000,
        25000
    ];

    constructor () PaymentSplitter(_payees, _shares) payable {}

}
