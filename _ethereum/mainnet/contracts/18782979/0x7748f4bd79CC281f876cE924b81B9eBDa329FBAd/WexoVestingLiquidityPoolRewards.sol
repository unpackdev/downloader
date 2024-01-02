// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./VestingWallet.sol";


contract WexoVestingLiquidityPoolRewards is VestingWallet {
    // start 22.6.2024 00:00 (Bratislava), duration 48 months
    constructor() VestingWallet(0x39594aA201Ff7DEff94ABebE1EB0036723F89599, 1719007200, 126230400) {

    }

}