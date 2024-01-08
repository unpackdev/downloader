// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./CompoundStrategy.sol";

// solhint-disable no-empty-blocks
/// @title Deposit USDC in Compound and earn interest.
contract CompoundStrategyUSDC is CompoundStrategy {
    string public constant NAME = "Compound-Strategy-USDC";
    string public constant VERSION = "3.0.0";

    // cUSDC = 0x39AA39c021dfbaE8faC545936693aC917d5E7563
    constructor(address _pool, address _swapManager)
        CompoundStrategy(_pool, _swapManager, 0x39AA39c021dfbaE8faC545936693aC917d5E7563)
    {}
}
