// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./MahaswapOracle.sol";
import "./IUniswapV2Pair.sol";

// Fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a
// longer period.
contract ArthDaiTwelveHourTWAPOracle is MahaswapOracle {
    constructor(IUniswapV2Pair _pair, uint256 _startTime)
        public
        MahaswapOracle(_pair, 43200, _startTime)
    {}
}
