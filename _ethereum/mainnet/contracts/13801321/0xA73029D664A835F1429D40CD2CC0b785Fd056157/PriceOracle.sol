// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./AggregatorV3Interface.sol";

/**
 * @notice chainlink price oracle.
 * This is the contract to fix the price at the nearest time after expiry.
 */
contract PriceOracle is Ownable {
    /// @dev expiry price with timestamp
    struct ExpiryPrice {
        uint256 price;
        uint256 timestamp;
    }

    /// @dev chainlink aggregator address of the underlying asset price
    mapping(address => AggregatorV3Interface) aggregators;

    /// @dev aggregator address => timestamp => expiry price
    mapping(address => mapping(uint256 => ExpiryPrice)) internal expiryPrices;

    event ExpiryPriceUpdated(address aggregator, uint256 expiry, uint256 price);

    uint256 public constant DISPUTE_PERIOD = 2 hours;

    /**
     * @notice set aggregator
     * only owner can set new aggregator
     */
    function setAggregator(address _aggregatorAddress) external onlyOwner {
        require(address(aggregators[_aggregatorAddress]) == address(0));
        aggregators[_aggregatorAddress] = AggregatorV3Interface(_aggregatorAddress);
    }

    /**
     * @notice set expiry price
     * anyone can set price if the price has not been setted.
     * Also timestamp must be later than expiration.
     */
    function setExpiryPrice(address _aggregator, uint256 _expiryTimestamp) external {
        (uint256 price, uint256 timestamp) = getPrice(_aggregator);

        require(_expiryTimestamp < timestamp, "PriceOracle: price timestamp must be later than expiry");

        ExpiryPrice storage expiryPrice = expiryPrices[_aggregator][_expiryTimestamp];

        require(expiryPrice.timestamp == 0, "PriceOracle: already setted");

        expiryPrice.price = price;
        expiryPrice.timestamp = timestamp;

        emit ExpiryPriceUpdated(_aggregator, _expiryTimestamp, price);
    }

    /**
     * @notice update expiry price
     * anyone can update price if the price has not been setted
     * or if new price's timestamp is earlier than previous one.
     * Also timestamp must be later than expiration.
     */
    function updateExpiryPrice(
        address _aggregator,
        uint256 _expiryTimestamp,
        uint80 _roundId
    ) external {
        (uint256 price, uint256 timestamp) = getHistoricalPrice(_aggregator, _roundId);

        require(_expiryTimestamp < timestamp, "PriceOracle: price timestamp must be later than expiry");

        ExpiryPrice storage expiryPrice = expiryPrices[_aggregator][_expiryTimestamp];

        require(
            expiryPrice.timestamp == 0 || expiryPrice.timestamp > timestamp,
            "PriceOracle: new price's timestamp must be close to expiry"
        );

        expiryPrice.price = price;
        expiryPrice.timestamp = timestamp;

        emit ExpiryPriceUpdated(_aggregator, _expiryTimestamp, price);
    }

    /**
     * @notice get price for an expiration
     * @return price price scaled by 1e8
     * @return _isFinalized returns true if price has been finalized, if not returns false
     */
    function getExpiryPrice(address _aggregator, uint256 _expiryTimestamp)
        external
        view
        returns (uint256 price, bool _isFinalized)
    {
        price = expiryPrices[_aggregator][_expiryTimestamp].price;
        _isFinalized = isFinalized(_aggregator, _expiryTimestamp);
    }

    /**
     * @notice return flag if price is finalized or not
     * true if dispute period has been passed and price has been setted more than once
     */
    function isFinalized(address _aggregator, uint256 _expiryTimestamp) internal view returns (bool) {
        return
            (_expiryTimestamp + DISPUTE_PERIOD < block.timestamp) &&
            expiryPrices[_aggregator][_expiryTimestamp].timestamp != 0;
    }

    /**
     * @notice get price scaled by 1e8
     */
    function getPrice(address _aggregatorAddress) public view returns (uint256, uint256) {
        (, int256 answer, , uint256 roundTimestamp, ) = aggregators[_aggregatorAddress].latestRoundData();

        require(answer > 0, "PriceOracle: price is lower than 0");

        return (uint256(answer), roundTimestamp);
    }

    function getHistoricalPrice(address _aggregatorAddress, uint80 _roundId) public view returns (uint256, uint256) {
        (, int256 answer, , uint256 roundTimestamp, ) = aggregators[_aggregatorAddress].getRoundData(_roundId);

        require(answer > 0, "PriceOracle: price is lower than 0");

        return (uint256(answer), roundTimestamp);
    }
}
