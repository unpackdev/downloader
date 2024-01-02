// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./FeedRegistryInterface.sol";

interface Aggregator {
  function minAnswer() external view returns (int192);
  function maxAnswer() external view returns (int192);
}

interface AggregatorInterface {
  function aggregator() external view returns (address);
  function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
}

abstract contract ChainlinkAdapter {
  ///@notice Address of the Chainlink feed registry
  address public clRegistry;

  ///@notice Address of the Gas Oracle feed
  AggregatorInterface public gasFeed;

  ///@notice BTC address for chainlink price feed
  address constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;

  ///@notice Denominations used to query price in USD
  address public constant USD = address(840);

  ///@notice Query the chainlink price for a given asset
  ///@param asset address of the asset to query
  ///@return Price and Timestamp, return 0 if there is no feed
  function _getChainlinkPrice(address asset, address clQuoteToken)
    internal
    view
    returns (uint256, uint256)
  {
    try FeedRegistryInterface(clRegistry).latestRoundData(asset, clQuoteToken) returns (
      uint80, int256 clPrice, uint256, uint256 updatedAt, uint80
    ) {
      uint256 decimals = FeedRegistryInterface(clRegistry).decimals(asset, clQuoteToken);
      address aggregator = FeedRegistryInterface(clRegistry).getFeed(asset, clQuoteToken);
      uint256 price = _chainlinkAnswerIsInRange(aggregator, clPrice)
        ? uint256(clPrice) * (10 ** (18 - decimals))
        : 0;
      return (price, updatedAt);
    } catch {
      uint256 price = 0;
      uint256 timestamp = 0;
      return (price, timestamp);
    }
  }

  function _chainlinkAnswerIsInRange(address aggregator, int256 clPrice)
    internal
    view
    returns (bool)
  {
    int192 minAnswer = Aggregator(aggregator).minAnswer();
    int192 maxAnswer = Aggregator(aggregator).maxAnswer();
    return clPrice > minAnswer && clPrice < maxAnswer;
  }

  function _getChainlink_wBtcPairPrice(address wbtc) internal view returns (uint256, uint256) {
    (, int256 wbtcPairPrice,, uint256 updatedAt,) =
      FeedRegistryInterface(clRegistry).latestRoundData(wbtc, BTC);
    uint256 decimals = FeedRegistryInterface(clRegistry).decimals(wbtc, BTC);
    uint256 adjustedPairPrice = uint256(wbtcPairPrice) * (10 ** (18 - decimals));
    return (adjustedPairPrice, updatedAt);
  }

  function _getGweiPrice() internal view returns (uint256) {
    try gasFeed.latestRoundData() returns (uint80, int256 gweiPrice, uint256, uint256, uint80) {
      address aggregator = gasFeed.aggregator();
      int192 minAnswer = Aggregator(aggregator).minAnswer();
      int192 maxAnswer = Aggregator(aggregator).maxAnswer();
      bool isInRange = gweiPrice > minAnswer && gweiPrice < maxAnswer;
      uint256 adjustedGweiPrice = isInRange ? uint256(gweiPrice) : 0;
      return adjustedGweiPrice;
    } catch {
      return 0;
    }
  }
}
