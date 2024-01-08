// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./EarnVesperMakerStrategy.sol";

//solhint-disable no-empty-blocks
contract EarnVesperMakerStrategyETH is EarnVesperMakerStrategy {
    string public constant NAME = "Earn-Vesper-Maker-Strategy-ETH";
    string public constant VERSION = "3.0.16";

    constructor(
        address _pool,
        address _cm,
        address _swapManager,
        address _vPool
    ) EarnVesperMakerStrategy(_pool, _cm, _swapManager, _vPool, "ETH-C", DAI) {}
}
