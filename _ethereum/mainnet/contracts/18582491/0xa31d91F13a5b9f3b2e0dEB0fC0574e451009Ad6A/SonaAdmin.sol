// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

import "./AccessControlUpgradeable.sol";
import "./UUPSUpgradeable.sol";

//  ___  _____  _  _    __      ___  ____  ____  ____    __    __  __
// / __)(  _  )( \( )  /__\    / __)(_  _)(  _ \( ___)  /__\  (  \/  )
// \__ \ )(_)(  )  (  /(__)\   \__ \  )(   )   / )__)  /(__)\  )    (
// (___/(_____)(_)\_)(__)(__)  (___/ (__) (_)\_)(____)(__)(__)(_/\/\_)

contract SonaAdmin is UUPSUpgradeable, AccessControl {
	/*//////////////////////////////////////////////////////////////
	/                            CONSTANTS
	//////////////////////////////////////////////////////////////*/
	/// @dev The bytes that represent an admin role
	bytes32 internal constant _ADMIN_ROLE = keccak256("ADMIN_ROLE");

	/*//////////////////////////////////////////////////////////////
	/                            FUNCTIONS
	//////////////////////////////////////////////////////////////*/

	/// @dev Modifier that ensures the calling wallet has the admin role
	modifier onlySonaAdmin() {
		_checkRole(_ADMIN_ROLE);
		_;
	}

	/// @dev Checks if the specified address is a Sona admin
	/// @param account The address to check
	function isSonaAdmin(address account) public view returns (bool) {
		return hasRole(_ADMIN_ROLE, account);
	}

	/// @dev SonaAdmin is authorized for upgrades
	function _authorizeUpgrade(
		address newImplementation
	) internal override onlySonaAdmin {} // solhint-disable no-empty-blocks

	/// @dev This empty reserved space is put in place to allow future versions to add new
	/// variables without shifting down storage in the inheritance chain.
	/// See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
	uint256[50] private __gap;
}
