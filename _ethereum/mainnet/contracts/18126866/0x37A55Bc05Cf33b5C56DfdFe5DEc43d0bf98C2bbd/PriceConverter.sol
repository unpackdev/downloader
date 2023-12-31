// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./AggregatorV3Interface.sol";

/**
 * @title The Price Converter library
 *
 * @notice The library consumes a generic price feed and provides a utility to
 * convert a value from one currency from another.
 *
 * - USD to ETH:
 *   - Mainnet price feed: https://etherscan.io/address/0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
 *   - Görli price feed: https://goerli.etherscan.io/address/0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
 *
 * All data feeds addresses can be found here:
 *
 * - https://docs.chain.link/data-feeds/price-feeds/addresses/
 */
library PriceConverter {
    /**
     * @dev Convert a currency to another one using the current exchange rate
     * defined in the data feed.
     *
     * @param aggregator The data feed to use for the conversion, see
     * https://docs.chain.link/data-feeds/price-feeds/addresses/ for a list of
     * data feeds.
     * @param value The value to convert. Important: `value` must be formatted
     * with 18 decimals.
     * @return The value, converted.
     */
    function convertTo(
        AggregatorV3Interface aggregator,
        int256 value
    ) internal view returns (int) {
        (, int256 price, , , ) = aggregator.latestRoundData();
        int256 mul = int(10) ** aggregator.decimals();
        return (value * price) / mul;
    }

    function convertFrom(
        AggregatorV3Interface aggregator,
        int256 value
    ) internal view returns (int) {
        (, int256 price, , , ) = aggregator.latestRoundData();
        int256 mul = int(10) ** aggregator.decimals();
        return (value * mul) / price;
    }
}
