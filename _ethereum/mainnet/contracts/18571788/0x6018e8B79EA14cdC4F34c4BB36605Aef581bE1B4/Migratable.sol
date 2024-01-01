// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {AccessControlDefaultAdminRules} from
  "@openzeppelin/contracts/access/AccessControlDefaultAdminRules.sol";

import "./IMigratable.sol";

/// @notice Base contract that adds migration functionality.
abstract contract Migratable is IMigratable, AccessControlDefaultAdminRules {
  /// @notice The address of the new contract that this contract will be upgraded to.
  address internal s_migrationTarget;

  function setMigrationTarget(address newMigrationTarget)
    external
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _validateMigrationTarget(newMigrationTarget);

    address oldMigrationTarget = s_migrationTarget;
    s_migrationTarget = newMigrationTarget;

    emit MigrationTargetSet(oldMigrationTarget, newMigrationTarget);
  }

  /// @inheritdoc IMigratable
  function getMigrationTarget() external view returns (address) {
    return s_migrationTarget;
  }

  /// @notice Helper function for validating the migration target
  /// @param newMigrationTarget The address of the new migration target
  function _validateMigrationTarget(address newMigrationTarget) internal virtual {
    if (
      newMigrationTarget == address(0) || newMigrationTarget == address(this)
        || newMigrationTarget == s_migrationTarget || newMigrationTarget.code.length == 0
    ) {
      revert InvalidMigrationTarget();
    }
  }

  /// @dev Reverts if the migration target is not set
  modifier validateMigrationTargetSet() {
    if (s_migrationTarget == address(0)) {
      revert InvalidMigrationTarget();
    }
    _;
  }
}
