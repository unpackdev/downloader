//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseSFTConcreteUpgradeable.sol";
import "./ISFTValueIssuableDelegate.sol";
import "./ISFTValueIssuableConcrete.sol";
import "./SFTIssuableConcrete.sol";

abstract contract SFTValueIssuableConcrete is ISFTValueIssuableConcrete, SFTIssuableConcrete {

	function __SFTValueIssuableConcrete_init() internal onlyInitializing {
		__SFTIssuableConcrete_init();
	}

	function __SFTValueIssuableConcrete_init_unchained() internal onlyInitializing {
	}

	function burnOnlyDelegate(uint256 tokenId_, uint256 burnValue_) external virtual override onlyDelegate {
		_burn(tokenId_, burnValue_);
	}

	function _burn(uint256 tokenId_, uint256 burnValue_) internal virtual;

	uint256[50] private __gap;
}