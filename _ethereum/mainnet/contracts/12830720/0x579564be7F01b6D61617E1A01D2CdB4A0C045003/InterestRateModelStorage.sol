// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

/**
 * @title ELYFI InterestRateModel
 * @author ELYSIA
 */
contract InterestRateModelStorage {
  uint256 internal _optimalUtilizationRate;

  uint256 internal _borrowRateBase;

  uint256 internal _borrowRateOptimal;

  uint256 internal _borrowRateMax;
}
