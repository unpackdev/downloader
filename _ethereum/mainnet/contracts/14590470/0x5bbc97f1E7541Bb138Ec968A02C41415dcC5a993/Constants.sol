// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import "./PercentageMath.sol";

enum AdapterType {
    NO_SWAP,
    UNISWAP_V2,
    UNISWAP_V3,
    CURVE_V1,
    LP_YEARN
}

enum CloseOperations {
    OPERATION_CLOSURE,
    OPERATION_REPAY,
    OPERATION_LIQUIDATION
}

// 25% of MAX_INT
uint256 constant MAX_INT_4 = 0x3fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

// FEE = 10%
uint256 constant DEFAULT_FEE_INTEREST = 1000; // 10%

// FEE + LIQUIDATION_FEE 2%
uint256 constant FEE_LIQUIDATION = 200;

// Liquidation premium 5%
uint256 constant LIQUIDATION_PREMIUM = 500;

// Liquidation premium 5%
uint256 constant LIQUIDATION_DISCOUNTED_SUM = PERCENTAGE_FACTOR -
    LIQUIDATION_PREMIUM;

// 100% - LIQUIDATION_FEE - LIQUIDATION_PREMIUM
uint256 constant UNDERLYING_TOKEN_LIQUIDATION_THRESHOLD = LIQUIDATION_DISCOUNTED_SUM -
    FEE_LIQUIDATION;

// Seconds in a year
uint256 constant SECONDS_PER_YEAR = 365 days;
uint256 constant SECONDS_PER_ONE_AND_HALF_YEAR = (SECONDS_PER_YEAR * 3) / 2;

// OPERATIONS

// Decimals for leverage, so x4 = 4*LEVERAGE_DECIMALS for openCreditAccount function
uint8 constant LEVERAGE_DECIMALS = 100;

// Maximum withdraw fee for pool in percentage math format. 100 = 1%
uint8 constant MAX_WITHDRAW_FEE = 100;

uint256 constant CHI_THRESHOLD = 9950;
uint256 constant HF_CHECK_INTERVAL_DEFAULT = 4;

uint256 constant EXACT_INPUT = 1;
uint256 constant EXACT_OUTPUT = 2;
