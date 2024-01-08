// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./AaveStrategy.sol";

//solhint-disable no-empty-blocks
contract AaveStrategyUNI is AaveStrategy {
    string public constant NAME = "Aave-Strategy-UNI";
    string public constant VERSION = "3.0.0";

    // aUNI = 0xB9D7CB55f463405CDfBe4E90a6D2Df01C2B92BF1
    constructor(address _pool, address _swapManager)
        AaveStrategy(_pool, _swapManager, 0xB9D7CB55f463405CDfBe4E90a6D2Df01C2B92BF1)
    {}
}
