// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

interface IStrategy {
  function rebalance() external;

  function shouldRebalance() external view returns (bool);
}
