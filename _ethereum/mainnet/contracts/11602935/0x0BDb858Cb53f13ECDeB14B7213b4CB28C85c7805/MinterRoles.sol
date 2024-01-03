// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./Administered.sol";

contract MinterRoles is Administered {

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  
  constructor (address root)
    // public
    Administered(root)
  {
    _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender), "Restricted to minters.");
    _;
  }

  function isMinter(address account) public virtual view returns (bool) {
    return hasRole(MINTER_ROLE, account);
  }  

  function addMinter(address account) public virtual onlyAdmin {
    grantRole(MINTER_ROLE, account);
  }

  function removeMinter(address account) public virtual onlyAdmin {
    revokeRole(MINTER_ROLE, account);
  }
  
}