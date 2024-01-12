// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

contract Muzi is Initializable, ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
	/// @custom:oz-upgrades-unsafe-allow constructor
	constructor() {
		_disableInitializers();
	}

	function initialize() initializer public {
		__ERC20_init("Muzi", "MUZI");
		__Ownable_init();
		__UUPSUpgradeable_init();

		_mint(msg.sender, 500000000 * 10 ** decimals());
	}

	function _authorizeUpgrade(address newImplementation)
	internal
	onlyOwner
	override
	{}
}
