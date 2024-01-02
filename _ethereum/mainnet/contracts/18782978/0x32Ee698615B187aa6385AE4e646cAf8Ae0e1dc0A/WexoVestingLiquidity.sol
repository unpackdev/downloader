// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./VestingWallet.sol";


contract WexoVestingLiquidity is VestingWallet {
    // start 22.12.2023 00:00 (Bratislava), duration 24 months
    constructor() VestingWallet(0xa7D606A5743135369B27242458C7aF4e46Cb6fD2, 1703199600, 63072000) {

    }

}