// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./ModuleMapConsumer.sol";
import "./Controlled.sol";
import "./IStrategyManager.sol";
import "./IIntegrationMap.sol";
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
        IStrategyMap.Integration[] calldata integrations,
        IStrategyMap.Token[] calldata tokens
    ) external override onlyManager {
        IIntegrationMap integrationMap = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        );
        for (uint256 i = 0; i < integrations.length; i++) {
            require(
                integrationMap.getIsIntegrationAdded(
                    integrations[i].integration
                )
            );
        }
        IStrategyMap(moduleMap.getModuleAddress(Modules.StrategyMap))
            .addStrategy(name, integrations, tokens);
    }

    /**
    @notice Updates the whitelisted tokens a strategy accepts for new deposits
    @dev This is a passthrough to StrategyMap.updateStrategyTokens
     */
    function updateStrategy(
        uint256 id,
        IStrategyMap.Integration[] calldata integrations,
        IStrategyMap.Token[] calldata tokens
    ) external override onlyManager {
        IIntegrationMap integrationMap = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        );
        for (uint256 i = 0; i < integrations.length; i++) {
            require(
                integrationMap.getIsIntegrationAdded(
                    integrations[i].integration
                )
            );
        }
        IStrategyMap(moduleMap.getModuleAddress(Modules.StrategyMap))
            .updateStrategy(id, integrations, tokens);
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
        IStrategyMap(moduleMap.getModuleAddress(Modules.StrategyMap))
            .updateName(id, name);
    }

    /**
        @notice Deletes a strategy
        @dev This is a pass through to StrategyMap.deleteStrategy
        */
    function deleteStrategy(uint256 id) external override onlyManager {
        IStrategyMap(moduleMap.getModuleAddress(Modules.StrategyMap))
            .deleteStrategy(id);
    }
}
