// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./VestingWallet.sol";


contract PyyckaVestingWallet1 is VestingWallet {
    // start 6.12.2023 00:00 (Bratislava), duration 10h
    constructor() VestingWallet(0x0B41c4cd5A7615aA4BB28b99A61C6c80028fb37e, 1701817200, 36000) {

    }

}