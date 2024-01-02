// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

uint8 constant RC_NO_COMPONENT = 0;
uint8 constant RC_UNISWAP_V2_SWAPPER = 1;
uint8 constant RC_UNISWAP_V3_SWAPPER = 2;
uint8 constant RC_CURVE_SWAPPER = 3;
uint8 constant RC_LIDO_SWAPPER = 4;
uint8 constant RC_WSTETH_WRAPPER = 5;
uint8 constant RC_YEARN_DEPOSITOR = 6;
uint8 constant RC_YEARN_WITHDRAWER = 7;
uint8 constant RC_CURVE_LP_DEPOSITOR = 8;
uint8 constant RC_CURVE_LP_WITHDRAWER = 9;
uint8 constant RC_CONVEX_DEPOSITOR = 10;
uint8 constant RC_CONVEX_WITHDRAWER = 11;
uint8 constant RC_SWAP_AGGREGATOR = 12;
uint8 constant RC_CLOSE_PATH_RESOLVER = 13;
uint8 constant RC_CURVE_LP_PATH_RESOLVER = 14;
uint8 constant RC_YEARN_PATH_RESOLVER = 15;
uint8 constant RC_CONVEX_PATH_RESOLVER = 16;
uint8 constant RC_BALANCER_SWAPPER = 17;
uint8 constant RC_ERC4626_DEPOSITOR = 18;
uint8 constant RC_ERC4626_WITHDRAWER = 19;
uint8 constant RC_ERC4626_PATH_RESOLVER = 20;
uint8 constant RC_WRAP_AGGREGATOR = 21;
uint8 constant RC_AAVE_V2_WRAPPER = 22;
uint8 constant RC_COMPOUND_V2_WRAPPER = 23;
uint8 constant RC_BALANCER_LP_DEPOSITOR = 24;
uint8 constant RC_BALANCER_LP_WITHDRAWER = 25;
uint8 constant RC_BALANCER_LP_PATH_RESOLVER = 26;
uint8 constant RC_AURA_DEPOSITOR = 27;
uint8 constant RC_AURA_WITHDRAWER = 28;
uint8 constant RC_AURA_PATH_RESOLVER = 29;
