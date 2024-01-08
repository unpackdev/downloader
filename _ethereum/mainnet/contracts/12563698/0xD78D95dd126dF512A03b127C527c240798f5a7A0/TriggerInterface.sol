// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.5.17;

/**
 * @notice Interface for creating or interacting with a Trigger contract
 * @dev All trigger contracts created must conform to this interface
 */
contract TriggerInterface {
  /// @notice Trigger name
  function name() external view returns (string memory);

  /// @notice Trigger symbol
  function symbol() external view returns (string memory);

  /// @notice Trigger description
  function description() external view returns (string memory);

  /// @notice Returns array of IDs, where each ID corresponds to a platform covered by this trigger
  /// @dev See documentation for mapping of ID number to platform
  function getPlatformIds() external view returns (uint256[] memory);

  /// @notice Returns address of recipient who receives subsidies for creating the trigger and associated protection market
  function recipient() external view returns (address);

  /// @notice Returns true if trigger condition has been met
  function isTriggered() external view returns (bool);

  /// @notice Checks trigger condition, sets isTriggered flag to true if condition is met, and returns the new trigger status
  function checkAndToggleTrigger() external returns (bool);
}
