// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library IBGLibrary {

    struct IBGPlan {
        uint IBGTokens;
        uint stakedIBGTokens;
        uint IBGYieldIncome;
        uint IBGYieldMatchingIncome;
        uint IBGYieldMatchingLostIncome;
        uint withdrawnInvestment;
        uint withdrawnYield;
    }
}