// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./VesperMakerStrategy.sol";

//solhint-disable no-empty-blocks
contract VesperMakerStrategyETH is VesperMakerStrategy {
    string public constant NAME = "Vesper-Maker-Strategy-ETH";
    string public constant VERSION = "3.0.16";

    constructor(
        address _pool,
        address _cm,
        address _swapManager,
        address _vPool
    ) VesperMakerStrategy(_pool, _cm, _swapManager, _vPool, "ETH-C") {}
}
