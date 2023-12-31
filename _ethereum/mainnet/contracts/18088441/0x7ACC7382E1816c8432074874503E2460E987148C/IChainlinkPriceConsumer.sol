// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChainlinkPriceConsumer {
    function getLatestData() external view returns (int);

    function getHistoricalPrice(uint80 roundId) external view returns (int256);
}
