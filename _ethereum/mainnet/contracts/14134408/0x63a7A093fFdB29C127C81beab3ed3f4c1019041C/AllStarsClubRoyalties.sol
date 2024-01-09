//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./PaymentSplitter.sol";

contract AllStarsClubRoyalties is PaymentSplitter {
    string public name = "AllStarsClubRoyalties";

    address[] private team_ = [
        0xd21694BC0f7BFbE3ec2CE3288EFafcd91993219b,
        0x47bcB4887D59c18A981647b2c683c2f8fE8bc29f,
        0xf4812a340455e6Eda92C5272272359171539AB38,
        0x567e7f90D97DD1De458C926e60242DfB42529fAd
    ];
    uint256[] private teamShares_ = [485,325,160,30];

    constructor()
        PaymentSplitter(team_, teamShares_)
    {
    }
}