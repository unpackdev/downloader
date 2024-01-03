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
  returns(int256, uint256, uint256, uint256)
  {
    ( uint80 roundId, int price, uint startedAt, uint timeStamp, uint80 answeredInRound ) = priceFeed.latestRoundData();


    uint256 calc1 = price.toUint256().mul(10 ** (18 - priceFeed.decimals())); //.div(10 ** 8); //priceFeed.decimals().toUint256());
    uint256 result1 = uint256(10e18).div(calc1);

    uint256 response1 = uint256(10e18).div(result1).mul(10e6);

    return (price, calc1, result1, response1);
  }

}

// .017574692442882249
// .000000001759912708
// .001754571490000000

// 566.904993200000000000