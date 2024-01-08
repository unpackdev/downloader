// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

struct CrowdsaleBaseConfig {
  // ERC20 token being sold address
  IERC20 token;

  // ERC20 token being sold decimals
  uint8 tokenDecimals;

  // Stable coin address
  IERC20 USD;

  // Stable coin decimals
  uint8 USDDecimals;

  // Amount of USD (as 8 decimals integer) for single
  // Ex. rate = 5000000, tokenDecimals = 4 is equal to
  // rate = 0.05 cents for single token (10000 with decimals)
  uint256 rate;

  // Timestamp after which vesting phase is started
  uint256 phaseSwitchTimestamp;

  // Vesting stages, each stage has timestamp and percent of unlocked balance
  Stage[] stages;

  // Address of price feed. It's expected to return current price of ETH with 8 decimals
  AggregatorV3Interface priceFeed;

  // Price restrictions for priceFeed
  PriceRestrictions priceRestrictions;

  // Max value in USD transferred by user when buying tokens
  uint256 maxUsdValue;
}

struct PriceRestrictions {
  // maximal age in seconds of price value received from priceFeed
  uint256 timeDiff;

  // minimal price value
  uint256 minValue;

  // maximal price value
  uint256 maxValue;
}

struct Stage {
  uint256 timestamp;
  uint256 percent;
}

interface AggregatorV3Interface {
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
