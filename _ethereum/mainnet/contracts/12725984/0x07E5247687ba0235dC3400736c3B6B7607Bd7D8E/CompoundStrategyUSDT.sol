// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./CompoundStrategy.sol";

// solhint-disable no-empty-blocks
/// @title Deposit USDT in Compound and earn interest.
contract CompoundStrategyUSDT is CompoundStrategy {
    string public constant NAME = "Compound-Strategy-USDT";
    string public constant VERSION = "3.0.3";

    // cUSDT = 0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9
    constructor(address _pool, address _swapManager)
        CompoundStrategy(_pool, _swapManager, 0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9)
    {}
}
