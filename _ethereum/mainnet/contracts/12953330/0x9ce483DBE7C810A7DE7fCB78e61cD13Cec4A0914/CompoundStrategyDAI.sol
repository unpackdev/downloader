// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./CompoundStrategy.sol";

// solhint-disable no-empty-blocks
/// @title Deposit DAI in Compound and earn interest.
contract CompoundStrategyDAI is CompoundStrategy {
    string public constant NAME = "Compound-Strategy-DAI";
    string public constant VERSION = "3.0.0";

    // cDAI = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643
    constructor(address _pool, address _swapManager)
        CompoundStrategy(_pool, _swapManager, 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643)
    {}
}
