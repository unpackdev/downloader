// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./AccessControl.sol";

/// @title RoleControl
/// @author wangfulong
/// @dev Implements Admin and Minter roles.
contract RoleControl is AccessControl {
	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

	constructor() {
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_grantRole(MINTER_ROLE, msg.sender);
	}

	modifier onlyAdmin() {
		require(isAdmin(msg.sender), "Restricted to Admins.");
		_;
	}

	modifier onlyMinterOrAdmin() {
		require(
			isAdmin(msg.sender) || isMinter(msg.sender),
			"Restricted to Admins or Minters"
		);
		_;
	}

	function isAdmin(address account) public view returns (bool) {
		return hasRole(DEFAULT_ADMIN_ROLE, account);
	}

	function isMinter(address account) public view returns (bool) {
		return hasRole(MINTER_ROLE, account);
	}

	function addAdmin(address account) public onlyAdmin {
		grantRole(DEFAULT_ADMIN_ROLE, account);
	}

	function addMinter(address account) public onlyAdmin {
		grantRole(MINTER_ROLE, account);
	}

	function removeMinter(address account) public onlyAdmin {
		revokeRole(MINTER_ROLE, account);
	}
}
