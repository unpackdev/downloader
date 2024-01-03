// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IX2PriceFeed {
    function latestAnswer() external view returns (int256);
    function latestRound() external view returns (uint80);
    function getRoundData(uint80 roundId) external view returns (uint80, int256, uint256, uint256, uint80);
}
