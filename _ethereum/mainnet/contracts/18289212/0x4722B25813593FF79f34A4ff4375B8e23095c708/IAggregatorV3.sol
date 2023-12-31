// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/**
 * @title IAggregatorV3
 *
 * @notice Defines the common interfaces for Chainlink price feeds
 */

interface IAggregatorV3 {
  /**
   * @notice Returns the decimals of price feed
   */
  function decimals() external view returns (uint8);

  /**
   * @notice Returns the description of this price feed
   */
  function description() external view returns (string memory);

  /**
   * @notice Returns the version of this price feed
   */
  function version() external view returns (string memory);

  /**
   * @notice Returns the last RoundData details of this price feed
   */
  function latestRoundData()
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
