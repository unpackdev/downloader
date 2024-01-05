// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library InvestmentLibrary {

    struct Investment {
        uint plan;
        uint investment;
        uint investmentTime;
        uint stakingPeriod;
        uint yieldRateValue;
        bool isUnstaked;
    }
}