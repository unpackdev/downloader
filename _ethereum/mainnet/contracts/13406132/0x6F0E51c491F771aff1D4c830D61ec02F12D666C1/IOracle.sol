// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;
pragma abicoder v2;


interface IOracle {
  struct PriceObservation {
    uint32 timestamp;
    uint224 priceCumulativeLast;
    uint224 ethPriceCumulativeLast;
  }

  function updatePrice(address token) external returns (bool);

  function updatePrices(address[] calldata tokens) external returns (bool[] memory);

  function getPriceObservationsInRange(
    address token,
    uint256 timeFrom,
    uint256 timeTo
  ) external view returns (PriceObservation[] memory prices);

  function computeAverageEthForTokens(
    address token,
    uint256 tokenAmount,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (uint144);

  function computeAverageTokensForEth(
    address token,
    uint256 wethAmount,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (uint144);
}