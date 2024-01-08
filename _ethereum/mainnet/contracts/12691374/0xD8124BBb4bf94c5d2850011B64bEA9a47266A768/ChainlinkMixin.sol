// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;

import "./IAggregatorV3Interface.sol";

contract ChainlinkMixin {
    event SetAggregator(address aggregator, bool inverseRate);

    AggregatorV3Interface internal aggregator;
    uint256 private immutable sFactorTarget;
    uint256 private sFactorSource;
    uint256 private inverseRate; // if true return rate as inverse (1 / rate)

    constructor(address _aggregator, bool _inverseRate, uint256 _sFactorTarget) {
        sFactorTarget = _sFactorTarget;
        _setAggregator(_aggregator, _inverseRate);
    }

    function _setAggregator(address _aggregator, bool _inverseRate) internal {
        aggregator = AggregatorV3Interface(_aggregator);
        sFactorSource = 10**aggregator.decimals();
        inverseRate = (_inverseRate == false) ? 0 : 1;
        emit SetAggregator(_aggregator, _inverseRate);
    }

    function _rate() internal view returns (uint256) {
        (, int256 rate, , , ) = aggregator.latestRoundData();
        if (inverseRate == 0) return uint256(rate) * sFactorTarget / sFactorSource;
        return (sFactorTarget * sFactorTarget) / (uint256(rate) * sFactorTarget / sFactorSource);
    }
}
