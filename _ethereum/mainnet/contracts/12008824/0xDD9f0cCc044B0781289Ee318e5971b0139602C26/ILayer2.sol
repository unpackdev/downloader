// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface ILayer2 {
  function operator() external view returns (address);
  function isLayer2() external view returns (bool);
  function currentFork() external view returns (uint);
  function lastEpoch(uint forkNumber) external view returns (uint);
  function changeOperator(address _operator) external;
}
