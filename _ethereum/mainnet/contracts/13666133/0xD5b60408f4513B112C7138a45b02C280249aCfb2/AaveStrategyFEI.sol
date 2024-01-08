// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./AaveStrategy.sol";

//solhint-disable no-empty-blocks
contract AaveStrategyFEI is AaveStrategy {
    string public constant NAME = "Aave-Strategy-FEI";
    string public constant VERSION = "3.0.21";

    // aFEI = 0x683923dB55Fead99A79Fa01A27EeC3cB19679cC3
    constructor(address _pool, address _swapManager)
        AaveStrategy(_pool, _swapManager, 0x683923dB55Fead99A79Fa01A27EeC3cB19679cC3)
    {}
}
