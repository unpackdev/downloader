// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

// 25% of MAX_INT
uint256 constant ALLOWANCE_THRESHOLD = type(uint96).max >> 3;

// FEE = 10%
uint256 constant DEFAULT_FEE_INTEREST = 1000; // 10%

// LIQUIDATION_FEE 2%
uint256 constant DEFAULT_FEE_LIQUIDATION = 200; // 2%

// LIQUIDATION PREMIUM
uint256 constant DEFAULT_LIQUIDATION_PREMIUM = 500; // 5%

// Default chi threshold
uint256 constant DEFAULT_CHI_THRESHOLD = 9950;

// Default full hf check interval
uint256 constant DEFAULT_HF_CHECK_INTERVAL = 4;

// Seconds in a year
uint256 constant SECONDS_PER_YEAR = 365 days;
uint256 constant SECONDS_PER_ONE_AND_HALF_YEAR = (SECONDS_PER_YEAR * 3) / 2;

// OPERATIONS

// Decimals for leverage, so x4 = 4*LEVERAGE_DECIMALS for openCreditAccount function
uint8 constant LEVERAGE_DECIMALS = 100;

// Maximum withdraw fee for pool in percentage math format. 100 = 1%
uint8 constant MAX_WITHDRAW_FEE = 100;

uint256 constant EXACT_INPUT = 1;
uint256 constant EXACT_OUTPUT = 2;
