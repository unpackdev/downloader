// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./VestingWallet.sol";


contract WexoVestingOperations is VestingWallet {
    // start 22.12.2023 00:00 (Bratislava), duration 12 months
    constructor() VestingWallet(0xe7680602cbF34d2e3543008869Ff0bEb401bB586, 1703199600, 31622400) {

    }

}