// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import "./ILiquidationsGraceSentinel.sol";
import "./Ownable.sol";

/// @title LiquidationsGraceSentinel
/// @author BGD Labs
/// @notice Registry to allow a temporary stop liquidations on Aave, for users
///   to have enough time to protect their positions, after a pause
/// - Mirroring the pause limitations: if the asset paused is debt or collateral involved
///   in a liquidation, the liquidation is not possible
/// - Being an emergency mechanism, it is designed to be controlled by an entity like the Aave Guardian
contract LiquidationsGraceSentinel is Ownable, ILiquidationsGraceSentinel {
  mapping(address => uint40) public override gracePeriodUntil;

  /// @notice Function to set grace period to one or multiple Aave underlyings
  /// @dev To enable a grace period, a timestamp in the future should be set,
  ///      To disable a grace period, any timestamp in the past works, like 0
  /// @param assets Address of the underlying asset listed on Aave
  /// @param until Timestamp when the liquidations' grace period will end
  function setGracePeriods(
    address[] calldata assets,
    uint40[] calldata until
  ) external override onlyOwner {
    require(assets.length == until.length, 'INCONSISTENT_PARAMS_LENGTH');
    for (uint256 i = 0; i < assets.length; i++) {
      gracePeriodUntil[assets[i]] = until[i];
      emit GracePeriodSet(assets[i], until[i]);
    }
  }
}
