// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2023 Tokemak Ops Ltd. All rights reserved.
pragma solidity 0.8.17;

import "./IStatsCalculator.sol";

contract ChainlinkStatsUpkeep {
    function checkUpkeep(bytes calldata checkData)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        (address addr) = abi.decode(checkData, (address));
        IStatsCalculator calc = IStatsCalculator(addr);
        upkeepNeeded = calc.shouldSnapshot();
        performData = checkData;
    }

    function performUpkeep(bytes calldata performData) external {
        (address addr) = abi.decode(performData, (address));
        IStatsCalculator calc = IStatsCalculator(addr);
        calc.snapshot();
    }
}
