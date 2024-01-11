// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./AggregatorProxy.sol";
import "./ChainlinkRoundIdCalc.sol";

contract ChainLinkPricer {
    using ChainlinkRoundIdCalc for AggregatorProxy;

    //AggregatorProxy public ethUsd;

    // constructor() {
    //     ethUsd = AggregatorProxy(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    // }

    function next(address pricer, uint256 roundId) public view returns (uint80) {
        return AggregatorProxy(pricer).next(roundId);
    }

    function prev(address pricer, uint256 roundId) public view returns (uint80) {
        return AggregatorProxy(pricer).prev(roundId);
    }

    function addPhase(uint16 _phase, uint64 _originalId) public pure returns (uint80) {
        return ChainlinkRoundIdCalc.addPhase(_phase, _originalId);
    }

    function parseIds(uint256 roundId) public pure returns (uint16, uint64) {
        return ChainlinkRoundIdCalc.parseIds(roundId);
    }

    function getLatestPrice(address pricer) public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = AggregatorProxy(pricer).latestRoundData();
        return price;
    }

    function getLatestRoundId(address pricer) public view returns (uint80) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = AggregatorProxy(pricer).latestRoundData();
        return roundID;
    }

    function getHistoricalPrice(address pricer, uint80 roundId) public view returns (int256) {
        (
            uint80 id, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = AggregatorProxy(pricer).getRoundData(roundId);
        require(timeStamp > 0, "Round not complete");
        return price;
    }

    function getHistoricalRoundData(address pricer, uint80 roundId) public view returns  (uint80, int, uint, uint, uint80) {
       return AggregatorProxy(pricer).getRoundData(roundId);
    }

    function getLatestRoundData(address pricer) public view returns (uint80, int, uint, uint, uint80) {
        return AggregatorProxy(pricer).latestRoundData();
    }
}