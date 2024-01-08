// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

library Constants {
    // Transaction events
    uint256 constant TXNCODE_LOAN_ADVANCED = 1000;
    uint256 constant TXNCODE_LOAN_PAYMENT_MADE = 2000;
    uint256 constant TXNCODE_ASSET_REDEEMED = 3000;
    uint256 constant TXNCODE_ASSET_EXTENDED = 4000;
    uint256 constant TXNCODE_ASSET_REPOSSESSED = 5000;
    uint32 constant SECONDS_TO_DAYS_FACTOR = 86400;
    uint128 constant LOAN_AMOUNT_MAX_INCREMENT = 300000000000000000;
    uint64 constant FEE_MAX_INCREMENT = 30000000000000000;
    uint16 constant LOAN_TERM_MAX = 180;
    uint16 constant LOAN_TERM_MIN = 14;
}
