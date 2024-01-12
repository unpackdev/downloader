// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./AccessControlUpgradeable.sol";

/**
 * @title AdminUpgradeable
 * @notice Base class for all the contracts which need convenience methods to operate admin rights
 * @author AlloyX
 */
abstract contract AdminUpgradeable is AccessControlUpgradeable {
  function __AdminUpgradeable_init(address deployer) internal onlyInitializing {
    __AccessControl_init();
    _setupRole(DEFAULT_ADMIN_ROLE, deployer);
  }

  modifier onlyAdmin() {
    require(isAdmin(msg.sender), "Restricted to admins");
    _;
  }

  function isAdmin(address account) public view returns (bool) {
    return hasRole(DEFAULT_ADMIN_ROLE, account);
  }

  function addAdmin(address account) public virtual onlyAdmin {
    grantRole(DEFAULT_ADMIN_ROLE, account);
  }

  function renounceAdmin() public virtual {
    renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }
}
