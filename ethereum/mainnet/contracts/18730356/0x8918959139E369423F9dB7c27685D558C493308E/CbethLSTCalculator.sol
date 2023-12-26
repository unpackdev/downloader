// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2023 Tokemak Ops Ltd. All rights reserved.
pragma solidity 0.8.17;

import "./LSTCalculatorBase.sol";
import "./IStakedTokenV1.sol";
import "./ISystemRegistry.sol";

contract CbethLSTCalculator is LSTCalculatorBase {
    constructor(ISystemRegistry _systemRegistry) LSTCalculatorBase(_systemRegistry) { }

    function calculateEthPerToken() public view override returns (uint256) {
        return IStakedTokenV1(lstTokenAddress).exchangeRate();
    }

    function isRebasing() public pure override returns (bool) {
        return false;
    }
}
