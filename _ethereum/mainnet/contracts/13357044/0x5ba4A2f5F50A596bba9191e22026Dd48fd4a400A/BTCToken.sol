// "SPDX-License-Identifier: UNLICENSED"

pragma solidity 0.8.7;

import "./BasicToken.sol";

contract BTCToken is BasicToken {
    constructor() BasicToken("AFIN-BTC Token", "ABTC") {}
}
