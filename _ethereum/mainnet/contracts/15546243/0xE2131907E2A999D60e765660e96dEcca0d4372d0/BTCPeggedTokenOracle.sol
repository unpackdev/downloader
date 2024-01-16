// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./AggregatorV3Interface.sol";
import "./SafeCast.sol";
import "./ITokenOracle.sol";
import "./UsingStalePeriod.sol";

/**
 * @title Oracle for BTC-pegged tokens that uses Chainlink's BTC/USD feed
 */
contract BTCPeggedTokenOracle is ITokenOracle, UsingStalePeriod {
    using SafeCast for int256;

    /// @notice Chainlink BTC/USD aggregator
    AggregatorV3Interface public immutable btcAggregator;

    constructor(AggregatorV3Interface btcAggregator_, uint256 stalePeriod_) UsingStalePeriod(stalePeriod_) {
        btcAggregator = btcAggregator_;
    }

    /// @inheritdoc ITokenOracle
    function getPriceInUsd(address) external view override returns (uint256 _priceInUsd) {
        (, int256 _price, , uint256 _lastUpdatedAt, ) = btcAggregator.latestRoundData();
        require(!_priceIsStale(_lastUpdatedAt), "stale-price");
        return _price.toUint256() * 1e10; // To 18 decimals
    }
}
