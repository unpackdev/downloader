/**
    FRLY
    Website: https://friendly.tech
    Twitter: https://twitter.com/friendlytechbot
    Telegram: https://t.me/friendlytechprofilescanner
    Bot: https://t.me/friendlytech_bot
**/
// SPDX-License-Identifier: GenesisBot.xyz
pragma solidity ^0.8.19;

import "./GenesisToken.sol";

contract FRLY is GenesisToken {
    constructor()
        GenesisToken(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
            InitParams(
                "Friendly.Tech",
                "FRLY",
                6,
                10_000_000,
                5,
                100,
                5,
                500,
                500,
                0,
                1,
                2,
                2,
                0x0000000000000000000000000000000000000000,
                0x6848A1FCf1a51Ef4b9448Af795E4A8532d58B40A,
                10000
            )
        )
    {}
}
