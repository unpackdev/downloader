// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./VestingWallet.sol";


contract WexoVestingReserveTeam is VestingWallet {
    // start 22.12.2024 00:00 (Bratislava), duration 24 months
    constructor() VestingWallet(0x8B6a0e55a15963b87d343970A7c998bAEf8a7Ecf, 1734822000, 63072000) {

    }

}