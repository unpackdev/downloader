// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorV3Interface.sol";
import "./Errs.sol";

contract PriceOracle is AggregatorV3Interface {
    string public description;

    uint8 public immutable decimals;
    address public immutable updater;

    struct Data {
        int224 price; // max 2.69599467e67
        uint32 timestamp; // max year 2106
    }

    Data public data;

    /// @param _updater The address that has permissions to update the price feed
    /// @param _description A short description of the price feed (eg "ETH/USD")
    /// @param _decimals The number of decimals in the price feed
    /// @param _price The initial price of the price feed
    constructor(
        address _updater,
        string memory _description,
        uint8 _decimals,
        int256 _price
    ) {
        _require(_decimals <= 18, Errs.INVALID_DECIMALS);
        _require(_price > 0, Errs.INVALID_PRICE);
        description = _description;
        decimals = _decimals;
        updater = _updater;
        data = Data({
            price: int224(_price),
            timestamp: uint32(block.timestamp)
        });
        emit AnswerUpdated(_price, 1, block.timestamp);
    }

    function updatePrice(int256 _price) external {
        _require(msg.sender == updater, Errs.ACCESS_DENIED);

        data = Data({
            price: int224(_price),
            timestamp: uint32(block.timestamp)
        });

        emit AnswerUpdated(_price, 1, block.timestamp);
    }

    function version() external pure returns (uint256) {
        return 1;
    }

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(
        uint80 /*_roundId*/
    )
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return _priceRoundData();
    }

    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return _priceRoundData();
    }

    function _priceRoundData()
        internal
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        // return values that can be validated by caller
        // to conform with a Chainlink oracle feed.
        return (1, data.price, data.timestamp, data.timestamp, 1);
    }
}
