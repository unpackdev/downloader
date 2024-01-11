// SPDX-License-Identifier: MIT
// Kovan
pragma solidity ^0.8.7;

import "./AggregatorV3Interface.sol";

contract PriceConsumerV3 {
  AggregatorV3Interface internal priceFeed;

  // initializes an interface object named priceFeed that uses AggregatorV3Interface and connects specifically to a proxy aggregator contract deployed at 0x9326BFA02ADD2366b30bacB125260Af641031331 on Kovan testnet
  constructor() {
    priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
  }

  function getLatestPrice() public view returns (int256) {
    (, int256 price, , , ) = priceFeed.latestRoundData();
    return price;
  }
}

// (
//   /*uint80 roundID*/,
//   int price,
//   /*uint startedAt*/,
//   /*uint timeStamp*/,
//   /*uint80 answeredInRound*/
// ) = priceFeed.latestRoundData();
