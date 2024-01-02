// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./VestingWallet.sol";


contract PyyckaVestingWallet2 is VestingWallet {
    // start 5.12.2023 12:00 (Bratislava), duration 6h
    constructor() VestingWallet(0x0B41c4cd5A7615aA4BB28b99A61C6c80028fb37e, 1701774000, 21600) {

    }

}