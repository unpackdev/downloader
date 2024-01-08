// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./CompoundCoverageStrategy.sol";

// solhint-disable no-empty-blocks
contract CompoundCoverageStrategyDAI is CompoundCoverageStrategy {
    string public constant NAME = "Compound-Coverage-Strategy-DAI";
    string public constant VERSION = "3.0.0";

    constructor(address _pool, address _swapManager)
        CompoundCoverageStrategy(_pool, _swapManager, 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643)
    {}
}
