// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.4;
import "./IStrategyMap.sol";

interface IStrategyManager {
  // #### Functions

  /**
  @notice Adds a new strategy to the strategy map. 
  @dev This is a passthrough to StrategyMap.addStrategy
   */
  function addStrategy(
    string calldata name,
    IStrategyMap.WeightedIntegration[] memory integrations,
    address[] calldata tokens
  ) external;

  /**
    @notice Updates a strategy's name
    @dev This is a pass through function to StrategyMap.updateName
 */
  function updateStrategyName(uint256 id, string calldata name) external;

  /**
    @notice Updates a strategy's integrations
    @dev This is a pass through to StrategyMap.updateIntegrations
 */
  function updateStrategyIntegrations(
    uint256 id,
    IStrategyMap.WeightedIntegration[] memory integrations
  ) external;

  /**
  @notice Updates the tokens that a strategy accepts
  @dev This is a passthrough to StrategyMap.updateStrategyTokens
   */
  function updateStrategyTokens(uint256 id, address[] calldata tokens) external;

  /**
    @notice Deletes a strategy
    @dev This is a pass through to StrategyMap.deleteStrategy
    */
  function deleteStrategy(uint256 id) external;
}
