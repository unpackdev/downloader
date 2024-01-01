// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface AggregatorV3Interface {
  function getAmountsOut(uint256, address[] memory) external view returns (uint256[] memory);
  function decimals() external view returns (uint8);

  function latestRoundData() external view returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}