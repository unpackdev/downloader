// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./AccessControlUpgradeable.sol";
import "./ErrorsAndEvents.sol";

contract RolesUpgradeable is AccessControlUpgradeable, ErrorsAndEvents {
  function __Roles_init() internal onlyInitializing {
    __Roles_init_unchained();
  }

  function __Roles_init_unchained() internal onlyInitializing {
    __AccessControl_init();
  }

  modifier onlyManager() virtual {
    if (!hasRole(MANAGER_ROLE, msg.sender)) {
      revert NotManager();
    }
    _;
  }

  modifier onlyMinter() virtual {
    if (!hasRole(MINTER_ROLE, msg.sender)) {
      revert NotMinter();
    }
    _;
  }

  modifier onlyUpgrader() virtual {
    if (!hasRole(UPGRADER_ROLE, msg.sender)) {
      revert NotUpgrader();
    }
    _;
  }

  /// @notice Adds an address as a minter
  /// @dev Can only be called by a manager
  /// @param minter address to add as a minter
  function addMinter(address minter) external virtual onlyManager {
    _grantRole(MINTER_ROLE, minter);

    emit MinterAdded(minter);
  }

  /// @notice Removes an address as a minter
  /// @dev Can only be called by a manager
  /// @param minter address to remove as a minter
  function removeMinter(address minter) external virtual onlyManager {
    _revokeRole(MINTER_ROLE, minter);

    emit MinterRemoved(minter);
  }

  /// @notice Add an address to the manager role
  /// @dev Can only be called by a manager
  /// @param manager address to add
  function addManager(address manager) external virtual onlyManager {
    _grantRole(MANAGER_ROLE, manager);

    emit ManagerAdded(manager);
  }

  /// @notice Remove an address from the manager role
  /// @dev Can only be called by a manager
  /// @param manager address to remove
  function removeManager(address manager) external virtual onlyManager {
    _revokeRole(MANAGER_ROLE, manager);

    emit ManagerRemoved(manager);
  }

  uint256[50] private __gap;
}
