// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./AggregatorV3Interface.sol";
import "./IPriceFeed.sol";

/**
 * If you are reading data feeds on L2 networks, you must
 * check the latest answer from the L2 Sequencer Uptime
 * Feed to ensure that the data is accurate in the event
 * of an L2 sequencer outage. See the
 * https://docs.chain.link/data-feeds/l2-sequencer-feeds
 * page for details.
 */

contract PriceFeedV3 is IPriceFeed {
    // constructor() {
    // }

    /**
     * Returns the latest answer.
     */
    function getRound(address pairFeedContract) 
        external  
        view 
        returns (PriceRound memory) {
            AggregatorV3Interface _priceFeed = AggregatorV3Interface(pairFeedContract);
        // prettier-ignore
        (   
            uint80  roundId,
            int256  answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80  answeredInRound
        ) = _priceFeed.latestRoundData();
        (uint8 decimals) = _priceFeed.decimals();
        return PriceRound(roundId, answeredInRound, answer, decimals, startedAt, updatedAt);
    }

    function getRound(address pairFeedContract, uint80 round)
        external
        view
        returns (PriceRound memory) {
            AggregatorV3Interface _priceFeed = AggregatorV3Interface(pairFeedContract);
        (   uint80  roundId,
            int256  answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80  answeredInRound
        ) = _priceFeed.getRoundData(round);
        (uint8 decimals) = _priceFeed.decimals();
        return PriceRound(roundId, answeredInRound, answer, decimals, startedAt, updatedAt);
    }
 }
