// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStablePool {
  function getLastInvariant() external view returns(uint256, uint256);
  function getSwapFeePercentage() external view returns(uint256);
  function totalSupply() external view returns(uint256);
  function getVault() external view returns (address);
  function getPoolId() external view returns (bytes32);
}