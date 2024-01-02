// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./VestingWallet.sol";


contract WexoVestingReserveEcosystem is VestingWallet {
    // start 22.12.2026 00:00 (Bratislava), duration 5 months
    constructor() VestingWallet(0xe3e2704fa0a088b83fEe0154c170c375AF263424, 1797894000, 13042800) {

    }

}