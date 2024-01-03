// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./StrategyBusd.sol";

contract StrategyBusdUsdc is StrategyBusd {
    constructor(address _controller, address _vault)
        public
        StrategyBusd(_controller, _vault, USDC)
    {
        // usdc
        underlyingIndex = 1;
        precisionDiv = 1e12;
    }
}
