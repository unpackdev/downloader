// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./AccessControlUpgradeable.sol";

/// @title AccessControlWithUpdater
/// @author CulturalSurround64<CulturalSurround64@gmail.com>(https://github.com/SurroundingArt64/)
/// @notice Describes common functions.
/// @dev Multiple uses. Used for second admin access. Granted only to contract(?)
contract AccessControlWithUpdater is AccessControlUpgradeable {
	mapping(address => bool) private _updateAdmins;

	event UpdateAccessSet(address indexed updateAdmin, bool enabled);

	/// @notice add/remove update admin
	/// @param _updateAdmin address
	/// @param enabled set as Admin?
	function setUpdateAccess(address _updateAdmin, bool enabled)
		external
		onlyOwner
	{
		_updateAdmins[_updateAdmin] = enabled;
		emit AdminAccessSet(_updateAdmin, enabled);
	}

	/// @notice check update admin status
	/// @param _admin address
	function isUpdateAdmin(address _admin) public view returns (bool) {
		return _updateAdmins[_admin];
	}

	modifier onlyUpdateAdmin() {
		require(
			isUpdateAdmin(_msgSender()) ||
				isAdmin(_msgSender()) ||
				_msgSender() == owner(),
			'Caller does not have admin access'
		);
		_;
	}
}
