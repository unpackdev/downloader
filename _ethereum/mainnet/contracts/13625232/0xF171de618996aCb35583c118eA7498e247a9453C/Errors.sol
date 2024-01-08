// SPDX-License-Identifier: MIT AND AGPL-3.0-only
pragma solidity 0.8.6;

abstract contract Errors {
    string internal constant ERROR_ZERO_AMOUNT = "ZERO_AMOUNT";
    string internal constant ERROR_ZERO_ADDRESS = "ZERO_ADDRESS";
    string internal constant ERROR_PAST_TIMESTAMP = "PAST_TIMESTAMP";
    string internal constant ERROR_NOT_ENOUGH_DOM = "NOT_ENOUGH_DOM";
    string internal constant ERROR_NOT_ENOUGH_ALLOWANCE = "NOT_ENOUGH_ALLOWANCE";
    string internal constant ERROR_NOT_ENOUGH_STAKE = "NOT_ENOUGH_STAKED";
    string internal constant ERROR_STAKING_NOT_STARTED = "STAKING_NOT_STARTED";
    string internal constant ERROR_EXPIRES_TOO_SOON = "EXPIRES_TOO_SOON";
    string internal constant ERROR_STAKING_PROHIBITED = "STAKING_PROHIBITED";
}
