// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "./SignedSafeMath.sol";
import "./Ownable.sol";
import "./AggregatorV3Interface.sol";

contract PriceConsumerV3 is Ownable {
  using SignedSafeMath for uint256;

  AggregatorV3Interface internal priceFeed;

  constructor()
  public
  Ownable()
  {
    priceFeed = AggregatorV3Interface(address(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419));
  }

  function getLatestPrice()
  public
  view
  returns(int)
  {
    (
      uint80 roundId,
      int price,
      uint startedAt,
      uint timeStamp,
      uint80 answeredInRound
    ) = priceFeed.latestRoundData();

    return price;
  }

  function getLatestPrice2()
  public
  view
  returns(int)
  {
    (
      uint80 roundId,
      int price,
      uint startedAt,
      uint timeStamp,
      uint80 answeredInRound
    ) = priceFeed.latestRoundData();

    return 1 / price;
  }

}