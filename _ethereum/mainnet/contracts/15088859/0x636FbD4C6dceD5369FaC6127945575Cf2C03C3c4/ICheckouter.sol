// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface ICheckouter {
    struct TokenInfo {
        address fiatOracle;
        address swapPair;    // bytes data; //a encoded call to replace swapPair mode.
        uint256 fiatDecimals;
        uint256 decimals;
    }

    enum BillingType {
        FIXED_AMOUNT,
        FIAT_ANCHORED
    }
}