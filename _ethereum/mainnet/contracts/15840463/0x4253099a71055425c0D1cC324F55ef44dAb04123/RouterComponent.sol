// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

enum RouterComponent {
    NO_COMPONENT,
    UNISWAP_V2_SWAPPER,
    UNISWAP_V3_SWAPPER,
    CURVE_SWAPPER,
    LIDO_SWAPPER,
    WSTETH_WRAPPER,
    YEARN_DEPOSITOR,
    YEARN_WITHDRAWER,
    CURVE_LP_DEPOSITOR,
    CURVE_LP_WITHDRAWER,
    CONVEX_DEPOSITOR,
    CONVEX_WITHDRAWER,
    SWAP_AGGREGATOR,
    CLOSE_PATH_RESOLVER,
    CURVE_LP_PATH_RESOLVER,
    YEARN_PATH_RESOLVER,
    CONVEX_PATH_RESOLVER
}
