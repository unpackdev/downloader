// SPDX-License-Identifier: MIT
// Kovan
pragma solidity ^0.8.7;

import "./AggregatorV3Interface.sol";

contract PriceConsumerV3 {
  AggregatorV3Interface internal priceFeed;

  // initializes priceFeed (an interface object) to point to the aggregator at 0x9326BFA02ADD2366b30bacB125260Af641031331, which is the proxy address for the Kovan ETH / USD data feed
  // the aggregator connects with several oracle nodes and aggregates the pricing data from those nodes
  constructor() { priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331); }

  function getLatestPrice() public view returns (int) {
    (
      /*uint80 roundID*/,
      int price,
      /*uint startedAt*/,
      /*uint timeStamp*/,
      /*uint80 answeredInRound*/
    ) = priceFeed.latestRoundData(); // return an integer, missing the decimal point
    return price;
  }
}