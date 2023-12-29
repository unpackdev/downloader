// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2023 Tokemak Ops Ltd. All rights reserved.
pragma solidity 0.8.17;

import "./LSTCalculatorBase.sol";
import "./IRocketTokenRETHInterface.sol";
import "./ISystemRegistry.sol";

contract RethLSTCalculator is LSTCalculatorBase {
    constructor(ISystemRegistry _systemRegistry) LSTCalculatorBase(_systemRegistry) { }

    function calculateEthPerToken() public view override returns (uint256) {
        return IRocketTokenRETHInterface(lstTokenAddress).getExchangeRate();
    }

    function isRebasing() public pure override returns (bool) {
        return false;
    }
}
