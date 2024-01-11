// SPDX-License-Identifier: MPL-2.0
pragma solidity =0.8.9;

import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./CompatibilityFallbackHandler.sol";
import "./ERC223Contract.sol";

contract CustomFallbakHandler is
	CompatibilityFallbackHandler,
	OwnableUpgradeable,
	UUPSUpgradeable
{
	function initialize() public initializer {
		__Ownable_init();
		__UUPSUpgradeable_init();
	}

	function _authorizeUpgrade(address) internal override onlyOwner {}
}
