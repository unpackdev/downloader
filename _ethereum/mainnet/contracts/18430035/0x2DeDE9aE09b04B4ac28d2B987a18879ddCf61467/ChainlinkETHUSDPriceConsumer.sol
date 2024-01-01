// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 .0;

import "./AggregatorV3Interface.sol";

contract ChainlinkETHUSDPriceConsumer {
    AggregatorV3Interface internal dataFeed;
    uint256 acceptableDelay = 3660;

    /**
     * Network: Sepolia
     * Aggregator: ETH/USD
     * Address: 0x694AA1769357215DE4FAC081bf1f309aDC325306
     */

    /**
     * Network: Mainnet
     * Aggregator: ETH/USD
     * Address: 0x5f4ec3df9cbd43714fe2740f5e3616155c5b8419
     */

    /**
     * Network: Goerli
     * Aggregator ETH/USD
     * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     */

    constructor(address aggregatorAddress) {
        dataFeed = AggregatorV3Interface(aggregatorAddress);
    }

    /**
     * Returns the latest answer.
     */
    // Gold has 8 decimals - same as BTC

    function getLatestData() public view returns (int) {
        // prettier-ignore
        (
        ,
        int answer,
        ,
        uint256 updatedAt,
    ) = dataFeed.latestRoundData();
        require(
            block.timestamp - updatedAt < acceptableDelay,
            "Stale price data"
        );
        return answer;
    }

    /**
     * Returns historical price for a round id.
     * roundId is NOT incremental. Not all roundIds are valid.
     * You must know a valid roundId before consuming historical data.
     *
     * ROUNDID VALUES:
     *    InValid:      18446744073709562300
     *    Valid:        18446744073709554683
     *
     * @dev A timestamp with zero value means the round is not complete and should not be used.
     */
    function getHistoricalPrice(uint80 roundId) public view returns (int256) {
        // prettier-ignore
        (
            ,
            int price,
            ,
            uint timeStamp,
        ) = dataFeed.getRoundData(roundId);
        require(timeStamp > 0, "Round not complete");
        return price;
    }
}
