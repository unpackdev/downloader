// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface BPool {
  function getCurrentTokens() external view returns (address[] memory tokens);

  function getFinalTokens() external view returns (address[] memory tokens);

  function getNormalizedWeight(address token) external view returns (uint256);

  function getBalance(address token) external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function getController() external view returns (address);
}
