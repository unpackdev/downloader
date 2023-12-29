// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2023 Tokemak Ops Ltd. All rights reserved.
pragma solidity 0.8.17;

import "./ISystemRegistry.sol";
import "./ICurveOwner.sol";
import "./ICurveV1StableSwap.sol";
import "./CurvePoolRebasingCalculatorBase.sol";

/// @title Curve V1 Pool With Rebasing Tokens
/// @notice Calculate stats for a Curve V1 StableSwap pool
contract CurveV1PoolRebasingStatsCalculator is CurvePoolRebasingCalculatorBase {
    constructor(ISystemRegistry _systemRegistry) CurvePoolRebasingCalculatorBase(_systemRegistry) { }

    function getVirtualPrice() internal override returns (uint256 virtualPrice) {
        ICurveV1StableSwap pool = ICurveV1StableSwap(poolAddress);
        ICurveOwner(pool.owner()).withdraw_admin_fees(address(pool));

        return pool.get_virtual_price();
    }
}
