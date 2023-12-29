// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2023 2023 Tokemak Ops Ltd. All rights reserved.
pragma solidity 0.8.17;

import "./IERC20.sol";

import "./ISystemRegistry.sol";
import "./IBalancerComposableStablePool.sol";
import "./BalancerStablePoolCalculatorBase.sol";
import "./BalancerUtilities.sol";

contract BalancerMetaStablePoolCalculator is BalancerStablePoolCalculatorBase {
    constructor(
        ISystemRegistry _systemRegistry,
        address _balancerVault
    ) BalancerStablePoolCalculatorBase(_systemRegistry, _balancerVault) { }

    function getVirtualPrice() internal view override returns (uint256 virtualPrice) {
        virtualPrice = BalancerUtilities._getMetaStableVirtualPrice(balancerVault, poolAddress);
    }

    function getPoolTokens() internal view override returns (IERC20[] memory tokens, uint256[] memory balances) {
        (tokens, balances) = BalancerUtilities._getPoolTokens(balancerVault, poolAddress);
    }
}
