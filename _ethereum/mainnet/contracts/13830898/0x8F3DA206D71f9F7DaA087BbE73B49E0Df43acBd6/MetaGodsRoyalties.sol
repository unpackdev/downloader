//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
    Copyrights Paladins-Tech
    All rights reserved
    For any commercial use contact us at paladins-tech.eth
 */

import "./PaymentSplitter.sol";

contract MetaGodsRoyalties is PaymentSplitter {
    string public name = "MetaGodsRoyalties";

    address[] private team_ = [
        0xbd1A43403E7E1Aa8DF3BCa2C644b2fC9AA31d068,
        0xd1E534925CE149a6Ab6343b6Db1d4F8D603be576
    ];
    uint256[] private teamShares_ = [97, 3];

    constructor()
        PaymentSplitter(team_, teamShares_)
    {
    }
}