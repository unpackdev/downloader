// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./PowerOracle.sol";

contract MockOracle is PowerOracle {
  constructor(
    address cvpToken_,
    address reservoir_,
    uint256 anchorPeriod_,
    TokenConfig[] memory configs_
  ) public PowerOracle(cvpToken_, reservoir_, anchorPeriod_, configs_) {}

  mapping(bytes32 => uint256) public mockedAnchorPrices;

  function mockSetUserReward(uint256 userId_, uint256 reward_) external {
    rewards[userId_] = reward_;
  }

  function mockSetPrice(bytes32 symbolHash_, uint128 value_) external {
    prices[symbolHash_] = Price(uint128(block.timestamp), value_);
  }

  event MockFetchMockedAnchorPrice(string symbol);

  function fetchAnchorPrice(
    string memory symbol,
    TokenConfig memory config,
    uint256 conversionFactor
  ) internal override returns (uint256) {
    bytes32 symbolHash = keccak256(abi.encodePacked(symbol));
    if (mockedAnchorPrices[symbolHash] > 0) {
      emit MockFetchMockedAnchorPrice(symbol);
      return mockedAnchorPrices[symbolHash];
    } else {
      return super.fetchAnchorPrice(symbol, config, conversionFactor);
    }
  }

  function mockSetAnchorPrice(string memory symbol, uint256 value) external {
    mockedAnchorPrices[keccak256(abi.encodePacked(symbol))] = value;
  }
}
