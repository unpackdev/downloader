// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./VestingWallet.sol";


contract WexoVestingStakingRewards is VestingWallet {
    // start 22.12.2023 00:00 (Bratislava), duration 48 months
    constructor() VestingWallet(0x94eDEd3EE9F5D4617fF3bF1711e7889b971f4126, 1703199600, 126230400) {

    }

}