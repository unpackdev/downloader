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
        IStrategyMap.Integration[] calldata integrations,
        IStrategyMap.Token[] calldata tokens
    ) external;

    /**
        @notice Updates a strategy's name
        @dev This is a pass through function to StrategyMap.updateName
     */
    function updateStrategyName(uint256 id, string calldata name) external;

    /**
      @notice Updates the tokens that a strategy accepts
      @dev This is a passthrough to StrategyMap.updateStrategyTokens
       */
    function updateStrategy(
        uint256 id,
        IStrategyMap.Integration[] calldata integrations,
        IStrategyMap.Token[] calldata tokens
    ) external;

    /**
        @notice Deletes a strategy
        @dev This is a pass through to StrategyMap.deleteStrategy
        */
    function deleteStrategy(uint256 id) external;
}
