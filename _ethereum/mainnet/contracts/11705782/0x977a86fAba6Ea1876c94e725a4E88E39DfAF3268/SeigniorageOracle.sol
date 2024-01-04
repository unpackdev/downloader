// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./UniswapOracle.sol";

// Fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a
// longer period
contract SeigniorageOracle is UniswapOracle {
    constructor(
        address _factory,
        address _cash,
        address _dai,
        uint256 _period,
        uint256 _startTime
    ) public UniswapOracle(_factory, _cash, _dai, _period, _startTime) {}
}
