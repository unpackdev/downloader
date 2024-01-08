// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./CompoundStableStrategy.sol";

// solhint-disable no-empty-blocks
contract CompoundStableStrategyDAI is CompoundStableStrategy {
    string public constant NAME = "Compound-Stable-Strategy-DAI";
    string public constant VERSION = "3.0.0";

    constructor(address _pool, address _swapManager)
        CompoundStableStrategy(_pool, _swapManager, 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643)
    {}
}
