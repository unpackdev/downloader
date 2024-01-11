// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

/**
 * @title ELYFI InterestRateModel
 * @author ELYSIA
 */

contract InterestRateModelStorage {
  uint256 public _optimalUtilizationRate;

  uint256 public _borrowRateBase;

  uint256 public _borrowRateOptimal;

  uint256 public _borrowRateMax;

  address internal _connector;
}
