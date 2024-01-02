// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Errors {
    string public constant AMOUNT_CANNOT_BE_ZERO = "1";
    string public constant RECIPIENT_CANNOT_BE_ZERO = "2";
    string public constant AMOUNT_RECEIVED_CANNOT_BE_ZERO = "3";
    string public constant RESTAKED_ETH_RECEIVED_AMOUNT_LESS_THAN_MIN_RETURN =
        "4";
    string public constant ONLY_EMERGENCY_OWNER = "5";
    string public constant EMERGENCY_OWNER_CANNOT_BE_ZERO = "6";
    string public constant WRONG_BATCH_PROVIDED = "7";
    string public constant INSUFFICIENT_NATIVE_FUNDS_PASSED = "8";
    string public constant ONLY_SELF = "9";
    string public constant ARRAY_LENGTH_MISMATCH = "10";
    string public constant INSUFFICIENT_FEE_PASSED = "11";
    string public constant VOLUME_CANNOT_BE_ZERO = "12";
    string public constant ONLY_NATIVE_TOKENS = "13";
    string public constant ONLY_STARGATE_COMPOSER = "14";
    string public constant ONLY_WHITELISTED_BRIDGES = "15";
    string public constant BRIDGE_ADAPTER_ADDRESS_CANNOT_BE_ZERO = "16";
    string public constant MULTICALLER_ADDRESS_CANNOT_BE_ZERO = "17";
    string public constant FEE_MANAGER_ADDRESS_CANNOT_BE_ZERO = "18";
    string public constant SWAP_FAILED = "19";
    string public constant ONLY_ACROSS_BRIDGE = "20";
    string public constant BRIDGE_TX_FAILED_ON_MULTICALL = "21";
    string public constant TOKEN_PASSED_CANNOT_BE_NULL_ADDRESS = "22";
}
