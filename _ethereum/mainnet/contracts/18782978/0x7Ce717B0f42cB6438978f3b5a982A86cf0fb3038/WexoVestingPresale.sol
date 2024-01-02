// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./VestingWallet.sol";


contract WexoVestingPresale is VestingWallet {
    // start 22.12.2024 00:00 (Bratislava), duration 5 months
    constructor() VestingWallet(0x3E6dE2f2d62d9CC44f49C829d06F5ea11346B9CC, 1734822000, 13042800) {

    }

}