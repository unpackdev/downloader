// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./UniversalGMUOracle.sol";

contract Oracle_WMATIC is UniversalGMUOracle {
    constructor(
        address base,
        address quote,
        IUniswapPairOracle pairOracle,
        AggregatorV3Interface chainlinkOracle,
        IOracle gmuOracle
    ) UniversalGMUOracle(base, quote, pairOracle, chainlinkOracle, gmuOracle) {}
}
