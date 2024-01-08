//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./VestingWallet.sol";

contract TeamVesting is VestingWallet {
    constructor(
        address beneficiaryAddress,
        uint64 startTimestamp
    ) VestingWallet(beneficiaryAddress, startTimestamp, 365 days) {}
}
