// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./StrategyPax.sol";

contract StrategyPaxDai is StrategyPax {
    constructor(address _controller, address _vault)
        public
        StrategyPax(_controller, _vault, DAI)
    {
        // dai
        underlyingIndex = 0;
        precisionDiv = 1;
    }
}
