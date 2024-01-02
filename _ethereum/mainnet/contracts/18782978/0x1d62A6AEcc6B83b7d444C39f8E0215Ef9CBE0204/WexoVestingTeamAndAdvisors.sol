// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./VestingWallet.sol";


contract WexoVestingTeamAndAdvisors is VestingWallet {
    // start 22.12.2028 00:00 (Bratislava), duration 60 months
    constructor() VestingWallet(0x0965f05951ef92A16F719bea63192193beF2285e, 1861052400, 157766400) {

    }

}