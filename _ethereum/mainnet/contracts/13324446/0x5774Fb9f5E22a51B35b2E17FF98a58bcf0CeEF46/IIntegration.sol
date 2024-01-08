// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.4;

interface IIntegration {
  /// @param tokenAddress The address of the deposited token
  /// @param amount The amount of the token being deposited
  function deposit(address tokenAddress, uint256 amount) external;

  /// @param tokenAddress The address of the withdrawal token
  /// @param amount The amount of the token to withdraw
  function withdraw(address tokenAddress, uint256 amount) external;

  /// @dev Deploys all tokens held in the integration contract to the integrated protocol
  function deploy() external;

  /// @dev Harvests token yield from the Aave lending pool
  function harvestYield() external;

  /// @dev This returns the total amount of the underlying token that
  /// @dev has been deposited to the integration contract
  /// @param tokenAddress The address of the deployed token
  /// @return The amount of the underlying token that can be withdrawn
  function getBalance(address tokenAddress) external view returns (uint256);
}
