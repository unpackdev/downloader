// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorV3Interface.sol";

abstract contract PriceConsumerV3 {
  AggregatorV3Interface internal priceFeed;

  int256 private constant fakePrice = 2000 * 10**8; // remember to multiply by 10 ** 8

  // Price feed for ETH/USD on Ethereum and Matic
  // Price feed for BNB/USD on BSC
  constructor() {
    if (block.chainid == 1) {
      // Ethereum mainnet
      priceFeed = AggregatorV3Interface(
        0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
      );
    } else if (block.chainid == 4) {
      // Rinkeby
      priceFeed = AggregatorV3Interface(
        0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
      );
    } else if (block.chainid == 56) {
      // BSC mainnet
      priceFeed = AggregatorV3Interface(
        0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
      );
    } else if (block.chainid == 97) {
      // BSC testnet
      priceFeed = AggregatorV3Interface(
        0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
      );
    } else {
      // Unit-test
    }
  }

  // The returned price must be divided by 10**8
  function getThePrice() public view returns (int256) {
    if (
      block.chainid == 1 ||
      block.chainid == 4 ||
      block.chainid == 56 ||
      block.chainid == 97
    ) {
      (, int256 price, , , ) = priceFeed.latestRoundData();
      return price;
    } else {
      return fakePrice;
    }
  }
}
