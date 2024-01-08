// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./StrategyYearnAffiliate.sol";

contract StrategyYearnCrvLusd is StrategyYearnAffiliate {
    // Token addresses
    address public constant crv_lusd_lp = 0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA;
    address public constant yearn_registry = 0x50c1a2eA0a861A967D9d0FFE2AE4012c2E053804;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        StrategyYearnAffiliate(
            crv_lusd_lp,
            yearn_registry,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}
}
