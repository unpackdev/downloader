// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./ModuleMapConsumer.sol";
import "./Controlled.sol";
import "./IStrategyManager.sol";
import "./IStrategyMap.sol";
import "./IYieldManager.sol";

contract StrategyManager is
  Initializable,
  ModuleMapConsumer,
  Controlled,
  IStrategyManager
{
  // #### Functions
  function initialize(address[] memory controllers_, address moduleMap_)
    public
    initializer
  {
    __Controlled_init(controllers_, moduleMap_);
  }

  /**
  @notice Adds a new strategy to the strategy map. 
  @dev This is a passthrough to StrategyMap.addStrategy
   */
  function addStrategy(
    string calldata name,
    IStrategyMap.WeightedIntegration[] memory integrations,
    address[] calldata tokens
  ) external override onlyManager {
    IStrategyMap(moduleMap.getModuleAddress(Modules.StrategyMap)).addStrategy(
      name,
      integrations,
      tokens
    );
  }

  /**
@notice Updates the whitelisted tokens a strategy accepts for new deposits
@dev This is a passthrough to StrategyMap.updateStrategyTokens
 */
  function updateStrategyTokens(uint256 id, address[] calldata tokens)
    external
    override
    onlyManager
  {
    IStrategyMap(moduleMap.getModuleAddress(Modules.StrategyMap)).updateTokens(
      id,
      tokens
    );
  }

  /**
    @notice Updates a strategy's name
    @dev This is a pass through function to StrategyMap.updateName
 */
  function updateStrategyName(uint256 id, string calldata name)
    external
    override
    onlyManager
  {
    IStrategyMap(moduleMap.getModuleAddress(Modules.StrategyMap)).updateName(
      id,
      name
    );
  }

  /**
    @notice Updates a strategy's integrations
    @dev This is a pass through to StrategyMap.updateIntegrations
 */
  function updateStrategyIntegrations(
    uint256 id,
    IStrategyMap.WeightedIntegration[] memory integrations
  ) external override onlyManager {
    IStrategyMap(moduleMap.getModuleAddress(Modules.StrategyMap))
      .updateIntegrations(id, integrations);
    IYieldManager(moduleMap.getModuleAddress(Modules.YieldManager)).deploy();
  }

  /**
    @notice Deletes a strategy
    @dev This is a pass through to StrategyMap.deleteStrategy
    */
  function deleteStrategy(uint256 id) external override onlyManager {
    IStrategyMap(moduleMap.getModuleAddress(Modules.StrategyMap))
      .deleteStrategy(id);
    IYieldManager(moduleMap.getModuleAddress(Modules.YieldManager)).rebalance();
  }
}
