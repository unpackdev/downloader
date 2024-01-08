// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Structs.sol";

library PriceFeedClient {
  function currentPrice(AggregatorV3Interface priceFeed, PriceRestrictions memory priceRestrictions)
    internal
    view
    returns (uint256)
  {
    (, int256 answer, , uint256 updatedAt, ) = priceFeed.latestRoundData();
    uint256 price = uint256(answer);

    require(answer >= 0, 'CS: invalid price feed');
    require(
      updatedAt >= block.timestamp - priceRestrictions.timeDiff,
      'CS: old price feed timestamp'
    );
    require(updatedAt <= block.timestamp, 'CS: future price feed timestamp');
    require(price >= priceRestrictions.minValue, 'CS: price feed value below min value');
    require(price <= priceRestrictions.maxValue, 'CS: price feed value exceeds max value');

    return price;
  }
}
