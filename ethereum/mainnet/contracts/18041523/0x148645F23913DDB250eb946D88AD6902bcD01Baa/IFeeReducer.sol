// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IFeeReducer {
  function percentDiscount(
    address wallet,
    address collateralToken,
    uint256 collateralAmount,
    uint16 leverage
  ) external view returns (uint256, uint256);
}
