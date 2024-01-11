// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./console.sol";

contract Admin is Context {
  mapping(address => bool) private _admins;

  event AdminAdded(address indexed account);
  event AdminRemoved(address indexed account);

  constructor() {
    _addAdmin(_msgSender());
  }

  modifier onlyAdmin() {
    require(
      isAdmin(_msgSender()),
      "AdminRole: caller does not have the Admin role"
    );
    _;
  }

  function isAdmin(address account) public view returns (bool) {
    return _admins[account];
  }

  function _addAdmin(address account) internal {
    _admins[account] = true;
    emit AdminAdded(account);
  }

  function _removeAdmin(address account) internal {
    require(_admins[account], "Admin: address not found");
    delete _admins[account];
    emit AdminRemoved(account);
  }
}
