// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.21;

library Constants {
    uint8 public constant FEE_TYPE_ETH_FIXED = 0;
    uint8 public constant FEE_TYPE_TOKEN_A = 1;
    uint8 public constant FEE_TYPE_TOKEN_B = 2;
    uint32 public constant TWO_YEARS_SECONDS = 2 * 365 * 24 * 60 * 60; // 2 YEARS
    address public constant NATIVE_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
}
