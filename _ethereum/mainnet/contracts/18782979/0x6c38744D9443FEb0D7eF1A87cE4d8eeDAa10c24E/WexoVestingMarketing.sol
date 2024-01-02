// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./VestingWallet.sol";


contract WexoVestingMarketing is VestingWallet {
    // start 22.12.2023 00:00 (Bratislava), duration 24 months
    constructor() VestingWallet(0x6c6c8f0517698BD0Fb7e687a6FA5DabFc3b75DA5, 1703199600, 63072000) {

    }

}