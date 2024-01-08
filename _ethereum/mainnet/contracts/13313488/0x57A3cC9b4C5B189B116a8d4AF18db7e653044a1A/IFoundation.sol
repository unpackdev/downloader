// SPDX-License-Identifier: bsl-1.1

pragma solidity ^0.8.6;

interface IFoundation {

  function submitLiquidationFee(uint fee) external;

  function distribute() external;
}
