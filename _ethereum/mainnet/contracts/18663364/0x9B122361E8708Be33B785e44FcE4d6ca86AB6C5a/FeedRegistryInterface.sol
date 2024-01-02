// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface FeedRegistryInterface {
  function decimals(address base, address quote) external view returns (uint8);

  function getFeed(address base, address quote) external view returns (address);

  function latestRoundData(address base, address quote)
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
