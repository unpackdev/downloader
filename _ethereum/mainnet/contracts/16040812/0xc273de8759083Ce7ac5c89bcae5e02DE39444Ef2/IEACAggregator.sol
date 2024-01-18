// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEACAggregator {
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}
