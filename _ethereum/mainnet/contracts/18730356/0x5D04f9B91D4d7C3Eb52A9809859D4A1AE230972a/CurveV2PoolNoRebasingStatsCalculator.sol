// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2023 Tokemak Ops Ltd. All rights reserved.
pragma solidity 0.8.17;

import "./ISystemRegistry.sol";
import "./ICryptoSwapPool.sol";
import "./CurvePoolNoRebasingCalculatorBase.sol";

/// @title Curve V2 Pool No Rebasing with reentrancy protection
/// @notice Calculate stats for a Curve V2 CryptoSwap pool
contract CurveV2PoolNoRebasingStatsCalculator is CurvePoolNoRebasingCalculatorBase {
    constructor(ISystemRegistry _systemRegistry) CurvePoolNoRebasingCalculatorBase(_systemRegistry) { }

    function getVirtualPrice() internal override returns (uint256 virtualPrice) {
        ICryptoSwapPool(poolAddress).claim_admin_fees();
        return ICryptoSwapPool(poolAddress).get_virtual_price();
    }
}
