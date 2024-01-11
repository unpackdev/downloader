// give the contract some SVG Code
// output an NFT URI with this SVG code
// Storing all the NFT metadata on-chain

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./OwnableUpgradeable.sol";

/// @title AccessControlUpgradeable
/// @author CulturalSurround64<CulturalSurround64@gmail.com>(https://github.com/SurroundingArt64/)
/// @notice Describes common functions.
/// @dev Multiple uses
contract AccessControlUpgradeable is OwnableUpgradeable {
	/// @notice is admin mapping
	mapping(address => bool) private _admins;

	event AdminAccessSet(address indexed admin, bool enabled);

	/// @param _admin address
	/// @param enabled set as Admin
	function _setAdmin(address _admin, bool enabled) internal {
		_admins[_admin] = enabled;
		emit AdminAccessSet(_admin, enabled);
	}

	/// @param __admins addresses
	/// @param enabled set as Admin
	function setAdmin(address[] memory __admins, bool enabled)
		external
		onlyOwner
	{
		for (uint256 index = 0; index < __admins.length; index++) {
			_setAdmin(__admins[index], enabled);
		}
	}

	/// @param _admin address
	function isAdmin(address _admin) public view returns (bool) {
		return _admins[_admin];
	}

	modifier onlyAdmin() {
		require(
			isAdmin(_msgSender()) || _msgSender() == owner(),
			'Caller does not have admin access'
		);
		_;
	}
}
