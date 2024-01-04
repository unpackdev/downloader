// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IAggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        );

    function latestAnswer() external view returns (int256);

    function decimals() external view returns (uint8);
}
