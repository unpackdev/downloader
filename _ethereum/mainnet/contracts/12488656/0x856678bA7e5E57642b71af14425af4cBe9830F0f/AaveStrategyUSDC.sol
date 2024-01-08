// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./AaveStrategy.sol";

//solhint-disable no-empty-blocks
contract AaveStrategyUSDC is AaveStrategy {
    string public constant NAME = "Aave-Strategy-USDC";
    string public constant VERSION = "3.0.1";

    // aUSDC = 0xBcca60bB61934080951369a648Fb03DF4F96263C
    constructor(address _pool, address _swapManager)
        AaveStrategy(_pool, _swapManager, 0xBcca60bB61934080951369a648Fb03DF4F96263C)
    {}
}
