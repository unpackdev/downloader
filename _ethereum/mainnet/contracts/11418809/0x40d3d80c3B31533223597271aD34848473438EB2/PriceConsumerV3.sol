// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "./SignedSafeMath.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./SafeCast.sol";
import "./AggregatorV3Interface.sol";

contract PriceConsumerV3 is Ownable {
  using SignedSafeMath for int256;
  using SafeMath for uint256;
  using SafeCast for uint256;
  using SafeCast for int256;
  using SafeCast for uint8;

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
  returns(uint)
  {
    (
      uint80 roundId,
      int price,
      uint startedAt,
      uint timeStamp,
      uint80 answeredInRound
    ) = priceFeed.latestRoundData();

    return 1 / (price.toUint256() / (10 ** priceFeed.decimals()/*.toUint256()*/));
  }

}