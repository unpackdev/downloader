//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./PaymentSplitter.sol";

contract Imnium is PaymentSplitter {
    string public name = "Imnium";

    address[] private team_ = [
        0xA2f0A9Fda26c2ACE84a9EF1Bab072630AA35605b,
        0x567e7f90D97DD1De458C926e60242DfB42529fAd,
        0x61932D0CA0d88Cf27FA71593b2d3DE4CF45168D6,
        0xE9aa20FCFb5c5d8e0137e5F6C7507aBac2EbeCd0,
        0xbc9d63dadc3141cCa17d828383339D60ff44dD73
    ];
    uint256[] private teamShares_ = [300, 285, 100, 4600, 4715];

    constructor()
        PaymentSplitter(team_, teamShares_)
    {
    }
}