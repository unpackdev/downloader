// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./StrategyGusd.sol";

contract StrategyGusdUsdc is StrategyGusd {
    constructor(address _controller, address _vault)
        public
        StrategyGusd(_controller, _vault, USDC)
    {
        // usdc
        underlyingIndex = 2;
        precisionDiv = 1e12;
    }
}
