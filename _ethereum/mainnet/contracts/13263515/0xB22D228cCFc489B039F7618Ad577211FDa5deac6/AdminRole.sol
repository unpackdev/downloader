// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./Context.sol";
import "./console.sol";

import "./Roles.sol";

contract AdminRole is Context {
  using Roles for Roles.Role;

  Roles.Role private _admins;

  event AdminAdded(address account);
  event AdminRemoved(address account);

  constructor () {
    _addAdmin(_msgSender());
  }

  modifier onlyAdmin() {
    console.log("MsgSender is ", _msgSender());
		require(isAdmin(_msgSender()), "AdminRole: caller does not have the Admin role");
		_;
  }

  function isAdmin(address account) public view returns (bool) {
		return _admins.has(account);
	}

  function addAdmin(address account) public virtual onlyAdmin {
		_addAdmin(account);
	}

	function renounceAdmin() public {
		_removeAdmin(_msgSender());
	}

  function _addAdmin(address admin) internal {
    _admins.add(admin);
    emit AdminAdded(admin);
  }

  function _removeAdmin(address admin) internal {
    _admins.remove(admin);
    emit AdminRemoved(admin);
  }
}
