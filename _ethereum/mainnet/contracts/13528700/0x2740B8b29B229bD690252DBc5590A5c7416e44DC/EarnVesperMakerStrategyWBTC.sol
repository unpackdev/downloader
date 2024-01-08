// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./EarnVesperMakerStrategy.sol";

//solhint-disable no-empty-blocks
contract EarnVesperMakerStrategyWBTC is EarnVesperMakerStrategy {
    string public constant NAME = "Earn-Vesper-Maker-Strategy-WBTC";
    string public constant VERSION = "3.0.15";

    constructor(
        address _pool,
        address _cm,
        address _swapManager,
        address _vPool
    ) EarnVesperMakerStrategy(_pool, _cm, _swapManager, _vPool, "WBTC-A", DAI) {}

    function convertFrom18(uint256 amount) public pure virtual override returns (uint256) {
        return amount / (10**10);
    }
}
