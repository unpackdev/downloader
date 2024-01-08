// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

import "./NutBerryEvents.sol";

// Audit-1: ok
contract UpgradableRollup is NutBerryEvents {
  /// @notice Returns the address who is in charge of changing the rollup implementation.
  /// This contract should be managed by a `ExecutionProxy` that in turn verifies governance decisions
  /// from the rollup.
  /// The rollup will be managed by a multisig in the beginning until moving to community governance.
  /// It should be noted that there should be a emergency contract on L1 that can be used to recover from bad upgrades
  /// in case the rollup is malfunctioning itself.
  function ROLLUP_MANAGER () public virtual view returns (address) {
  }

  /// @notice Upgrades the implementation.
  function upgradeRollup (address newImplementation) external {
    require(msg.sender == ROLLUP_MANAGER());
    assembly {
      // uint256(-1) - stores the contract address to delegate calls to (RollupProxy)
      sstore(not(returndatasize()), newImplementation)
    }
    emit NutBerryEvents.RollupUpgrade(newImplementation);
  }
}
