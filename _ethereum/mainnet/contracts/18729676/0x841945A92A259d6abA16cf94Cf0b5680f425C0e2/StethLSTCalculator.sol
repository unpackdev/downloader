// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2023 Tokemak Ops Ltd. All rights reserved.
pragma solidity 0.8.17;

import "./LSTCalculatorBase.sol";
import "./IstEth.sol";
import "./ISystemRegistry.sol";

contract StethLSTCalculator is LSTCalculatorBase {
    constructor(ISystemRegistry _systemRegistry) LSTCalculatorBase(_systemRegistry) { }

    function calculateEthPerToken() public view override returns (uint256) {
        return IstEth(lstTokenAddress).getPooledEthByShares(1 ether);
    }

    function isRebasing() public pure override returns (bool) {
        return true;
    }
}
