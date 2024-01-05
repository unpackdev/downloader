// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./AccessControl.sol";
import "./IPermissions.sol";

/// @title IPermissions implementation
contract Permissions is IPermissions, AccessControl {
	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
	bytes32 public constant GOVERN_ROLE = keccak256("GOVERN_ROLE");
	bytes32 public constant REVOKE_ROLE = keccak256("REVOKE_ROLE");

	constructor() public {
		_setupGovernor(msg.sender);
		_setRoleAdmin(MINTER_ROLE, GOVERN_ROLE);
		_setRoleAdmin(GOVERN_ROLE, GOVERN_ROLE);
		_setRoleAdmin(REVOKE_ROLE, GOVERN_ROLE);
	}

	modifier onlyGovernor() {
		require(isGovernor(msg.sender), "Caller is not a governor");
		_;
	}

	modifier onlyRevoker() {
		require(isRevoker(msg.sender), "Caller is not a revoker");
		_;
	}

    modifier onlyMinter() {
      require(isMinter(msg.sender), "Caller is not a minter");
      _;
    }

	function createRole(bytes32 role, bytes32 adminRole) external override onlyGovernor {
		_setRoleAdmin(role, adminRole);
	}

	function grantMinter(address minter) external override onlyGovernor {
		grantRole(MINTER_ROLE, minter);
	} 

	function grantGovernor(address governor) external override onlyGovernor {
		grantRole(GOVERN_ROLE, governor);
	}

	function grantRevoker(address revoker) external override onlyGovernor {
		grantRole(REVOKE_ROLE, revoker);
	}

	function revokeMinter(address minter) external override onlyGovernor {
		revokeRole(MINTER_ROLE, minter);
	} 

	function revokeGovernor(address governor) external override onlyGovernor {
		revokeRole(GOVERN_ROLE, governor);
	}

	function revokeRevoker(address revoker) external override onlyGovernor {
		revokeRole(REVOKE_ROLE, revoker);
	}

	function revokeOverride(bytes32 role, address account) external override onlyRevoker {
		this.revokeRole(role, account);
	}

	function isMinter(address _address) public override view returns (bool) {
		return hasRole(MINTER_ROLE, _address);
	}

	// only virtual for testing mock override
	function isGovernor(address _address) public override view virtual returns (bool) {
		return hasRole(GOVERN_ROLE, _address);
	}

	function isRevoker(address _address) public override view returns (bool) {
		return hasRole(REVOKE_ROLE, _address);
	}

	function _setupGovernor(address governor) internal {
		_setupRole(GOVERN_ROLE, governor);
	}
}