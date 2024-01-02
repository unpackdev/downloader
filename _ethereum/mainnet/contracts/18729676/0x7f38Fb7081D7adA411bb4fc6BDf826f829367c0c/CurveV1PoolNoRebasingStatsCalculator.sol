// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2023 Tokemak Ops Ltd. All rights reserved.
pragma solidity 0.8.17;

import "./ISystemRegistry.sol";
import "./ICurveV1StableSwap.sol";
import "./CurvePoolNoRebasingCalculatorBase.sol";

/// @title Curve V1 Pool No Rebasing
/// @notice Calculate stats for a Curve V1 StableSwap pool
/// @dev Do not use this contract for pools with ETH due to a reentrancy issue
contract CurveV1PoolNoRebasingStatsCalculator is CurvePoolNoRebasingCalculatorBase {
    constructor(ISystemRegistry _systemRegistry) CurvePoolNoRebasingCalculatorBase(_systemRegistry) { }

    function getVirtualPrice() internal view override returns (uint256 virtualPrice) {
        // NOTE: this contract is not intended to be used with ETH pools due to reentrancy issues
        return ICurveV1StableSwap(poolAddress).get_virtual_price();
    }
}
