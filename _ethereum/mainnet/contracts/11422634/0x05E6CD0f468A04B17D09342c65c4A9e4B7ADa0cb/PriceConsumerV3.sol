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
  returns(int256, uint256, uint256, uint256, uint256, uint256)
  {
    ( uint80 roundId, int price, uint startedAt, uint timeStamp, uint80 answeredInRound ) = priceFeed.latestRoundData();


    uint256 result1 = price.toUint256();//.div(10 ** 8); //priceFeed.decimals().toUint256());
    uint256 result2 = result1.mul(10 ** 10); //priceFeed.decimals().toUint256());

    uint256 resultchk2 = result2.div(10e18);

    uint256 response1 = uint256(10e18).div(result1).mul(10e6);
    uint256 response2 = uint256(10e18).div(result2);
    // uint256 response3 = uint256(10e19).div(result).mul(10e18);

    // return (price, price.toUint256(), response1, response2, response3);
    return (price, result1, result2, resultchk2, response1, response2);
  }

}

// .017574692442882249
// .000000001759912708
// .001754571490000000