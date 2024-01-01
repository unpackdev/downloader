// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.18;

uint256 constant MIN_INPUT_AMOUNT = 1e14; // 0.0001
uint256 constant MAX_INPUT_AMOUNT = 1e33;
uint256 constant MIN_RESERVE_DEDUCTION = 1e3;
uint256 constant INITIAL_RESERVE_DEDUCTION_DIVIDER = 1e4;
uint256 constant DEFAULT_DECIMALS = 18;
uint256 constant UINT_ONE = 1e18;
uint256 constant UINT_TWO = 2e18;
uint256 constant UINT_FOUR = 4e18;
uint256 constant LP_FEE_PERCENT = 25e14;
uint256 constant STAKE_FEE_PERCENT = 25e14;
uint256 constant PROTOCOL_FEE_PERCENT = 5e15;
uint256 constant MAX_FEE_PERCENT = 1e17;
uint256 constant MAX_INVARIANT_CHANGE = 1e12; //Max allowed change percent: 0.000001 -> 0.0001%
uint256 constant MAX_UTIL_CHANGE = 1e12; //Max allowed change percent: 0.000001 -> 0.0001%

uint256 constant SECONDS_PER_DAY = 864e20;

uint8 constant MAX_ACTION_COUNT = 4;
uint8 constant MAX_FEE_TYPE_COUNT = 3;
uint8 constant MAX_FEE_STATE_FOR_USER_COUNT = 2;
uint8 constant MAX_FEE_STATE_COUNT = 3;
uint8 constant MAX_EMA_STATE_COUNT = 2;

uint8 constant PREVIOUS_EMA_INDEX = 0;
uint8 constant CURRENT_EMA_INDEX = 1;

uint256 constant UTILIZATION = 5e17; // 0.5
uint256 constant UTILIZATION_RECIPROCAL = 2e18;

address constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

//Value map to enum RewardType
uint256 constant REWARD_LP = 0;
uint256 constant REWARD_STAKE = 1;
uint256 constant REWARD_PROTOCOL = 2;

// Value map to enum FeeType
uint256 constant FEE_IBC_FROM_TRADE = 0;
uint256 constant FEE_IBC_FROM_LP = 1;
uint256 constant FEE_RESERVE = 2;
