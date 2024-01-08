// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./AaveStrategy.sol";

//solhint-disable no-empty-blocks
contract AaveStrategyUSDT is AaveStrategy {
    string public constant NAME = "Aave-Strategy-USDT";
    string public constant VERSION = "3.0.6";

    // aUSDT = 0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811
    constructor(address _pool, address _swapManager)
        AaveStrategy(_pool, _swapManager, 0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811)
    {}
}
