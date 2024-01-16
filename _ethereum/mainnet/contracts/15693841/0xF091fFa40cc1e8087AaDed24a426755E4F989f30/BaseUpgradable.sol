// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./console.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./Context.sol";

abstract contract BaseUpgradable is
	Initializable,
	OwnableUpgradeable,
	UUPSUpgradeable,
    ERC721Upgradeable
{
	using AddressUpgradeable for address;

	uint public version;

	/// @custom:oz-upgrades-unsafe-allow constructor
	function initialize(string memory name, string memory symbol) public initializer {
		__Ownable_init();
		__UUPSUpgradeable_init();
        __ERC721_init(name, symbol);
		version = 1;
		console.log("v", version);
	}

	function _authorizeUpgrade(address newImplementation)
		internal
		onlyOwner
		override
	{}
}