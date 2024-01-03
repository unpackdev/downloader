// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import "./AccessControl.sol";
import "./Ownable.sol";

contract Administered is AccessControl, Ownable {
  constructor (address root)
    // public
  {
    _setupRole(DEFAULT_ADMIN_ROLE, root);
  }

  modifier onlyAdmin()
  {
    require(isAdmin(msg.sender), "Restricted to admins.");
    _;
  }

  function isAdmin(address account) public virtual view returns (bool)
  {
    return hasRole(DEFAULT_ADMIN_ROLE, account);
  }

  function addAdmin(address account) public virtual onlyAdmin
  {
    grantRole(DEFAULT_ADMIN_ROLE, account);
  }

  function renounceAdmin() public virtual
  {
    renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }
}