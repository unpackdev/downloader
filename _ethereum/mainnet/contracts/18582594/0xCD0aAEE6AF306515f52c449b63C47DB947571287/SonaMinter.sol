// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

import "./SonaAdmin.sol";
import "./ERC721.sol";
import "./UUPSUpgradeable.sol";

//  ___  _____  _  _    __      ___  ____  ____  ____    __    __  __
// / __)(  _  )( \( )  /__\    / __)(_  _)(  _ \( ___)  /__\  (  \/  )
// \__ \ )(_)(  )  (  /(__)\   \__ \  )(   )   / )__)  /(__)\  )    (
// (___/(_____)(_)\_)(__)(__)  (___/ (__) (_)\_)(____)(__)(__)(_/\/\_)

abstract contract SonaMinter is SonaAdmin, ERC721 {
	/*//////////////////////////////////////////////////////////////
	/                            CONSTANTS
	//////////////////////////////////////////////////////////////*/
	/// @dev The bytes that represent an admin role
	bytes32 internal constant _MINTER_ROLE = keccak256("MINTER_ROLE");

	/// @dev to be called in the child initializer
	function initializeMinterRole() public virtual onlyInitializing {
		_setRoleAdmin(_MINTER_ROLE, _ADMIN_ROLE);
	}

	/// @dev Modifier that ensures the caller has the minter role
	modifier onlySonaMinter() {
		_checkRole(_MINTER_ROLE);
		_;
	}

	/// @dev Resolves conflict between ERC721AUpgradable and AccessControl so we don't have to do it on a per contract basis.
	function supportsInterface(
		bytes4 interfaceId
	) public view virtual override(ERC721, AccessControl) returns (bool) {
		return
			ERC721.supportsInterface(interfaceId) ||
			AccessControl.supportsInterface(interfaceId);
	}

	/// @dev This empty reserved space is put in place to allow future versions to add new
	/// variables without shifting down storage in the inheritance chain.
	/// See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
	uint256[50] private __gap;
}
