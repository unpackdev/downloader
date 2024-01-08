// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./VesperMakerStrategy.sol";

//solhint-disable no-empty-blocks
contract VesperMakerStrategyWBTC is VesperMakerStrategy {
    string public constant NAME = "Vesper-Maker-Strategy-WBTC";
    string public constant VERSION = "3.0.15";

    constructor(
        address _pool,
        address _cm,
        address _swapManager,
        address _vPool
    ) VesperMakerStrategy(_pool, _cm, _swapManager, _vPool, "WBTC-A") {}
}
