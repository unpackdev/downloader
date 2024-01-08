// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.5.0;

interface IIyusdiBondingCurve {
  function getPrintPrice(uint256 curve, uint256 printNumber, uint256[] calldata parms) external view returns (uint256 price);
}
