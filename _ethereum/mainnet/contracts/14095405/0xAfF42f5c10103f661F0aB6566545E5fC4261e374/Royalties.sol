//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./PaymentSplitter.sol";

contract MaskBillionaireRoyalties is PaymentSplitter {
    string public name = "MaskBillionaireRoyalties";

    address[] private team_ = [
        0x6E25d1162679B8D8Ec85603f235C016029548eEc,
        0x12FacD947BeF9F3049735E4978d09C1035f74cc1,
        0x79fe014A5FeFb1c49f32dFE1bB3dA463877973E8,
        0xA32fA46906316611EaeDcCeDB926c4009c78054A,
        0x040FC936073ff3233DF246b41e82310C97CbA7d4,
        0xd1E534925CE149a6Ab6343b6Db1d4F8D603be576
    ];
    uint256[] private teamShares_ = [240, 240, 240, 245, 20, 15];

    constructor()
        PaymentSplitter(team_, teamShares_)
    {
    }
}