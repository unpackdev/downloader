// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface ILiquidationsGraceSentinel {
  /**
   * @dev Emitted when a new grace period is set
   * @param asset Address of the underlying asset listed on Aave
   * @param until Timestamp until the grace period will be activated
   **/
  event GracePeriodSet(address indexed asset, uint40 until);

  /**
   * @dev Returns until when a grace period is enabled
   * @param asset Address of the underlying asset listed on Aave
   **/
  function gracePeriodUntil(address asset) external view returns (uint40);

  /// @notice Function to set grace period to one or multiple Aave underlyings
  /// @dev To enable a grace period, a timestamp in the future should be set,
  ///      To disable a grace period, any timestamp in the past works, like 0
  /// @param assets Address of the underlying asset listed on Aave
  /// @param until Timestamp when the liquidations' grace period will end
  function setGracePeriods(address[] calldata assets, uint40[] calldata until) external;
}
