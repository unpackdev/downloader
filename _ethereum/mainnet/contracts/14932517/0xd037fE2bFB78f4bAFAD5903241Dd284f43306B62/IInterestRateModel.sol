// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./DataStruct.sol";

interface IInterestRateModel {
  function calculateRates(
    uint256 lTokenAssetBalance,
    uint256 totalDTokenBalance,
    uint256 depositAmount,
    uint256 borrowAmount,
    uint256 moneyPoolFactor
  ) external view returns (uint256, uint256);

  function updateOptimalUtilizationRate(
    uint256 optimalUtilizationRate
  ) external;

  function updateBorrowRateBase(
    uint256 borrowRateBase
  ) external;

  function updateBorrowRateOptimal(
    uint256 borrowRateOptimal
  ) external;

  function updateBorrowRateMax(
    uint256 borrowRateMax
  ) external;
}
