// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./CompoundMakerStrategy.sol";
import "./IToken.sol";

//solhint-disable no-empty-blocks
contract CompoundMakerStrategyUNI is CompoundMakerStrategy {
    string public constant NAME = "Compound-Maker-Strategy-UNI";
    string public constant VERSION = "3.0.9";

    // cDAI = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643
    constructor(
        address _pool,
        address _cm,
        address _swapManager
    ) CompoundMakerStrategy(_pool, _cm, _swapManager, 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643, "UNI-A") {}
}
