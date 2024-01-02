// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./VestingWallet.sol";


contract WexoVestingBounty is VestingWallet {
    // start 22.12.2024 00:00 (Bratislava), duration 5 months
    constructor() VestingWallet(0x1d0552B36F4E95716357Ea7e4ec752dbbFc61C7F, 1734822000, 13042800) {

    }

}