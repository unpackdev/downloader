// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

/**
 * @title
 */
interface IUSYCAggregator {
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function reportBalance(uint256 principal, uint256 interest, uint totalSupply) external returns (uint80 roundId);
}
