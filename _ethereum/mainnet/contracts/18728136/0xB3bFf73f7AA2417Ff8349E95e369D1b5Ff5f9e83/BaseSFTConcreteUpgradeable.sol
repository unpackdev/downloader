// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./OwnControl.sol";
import "./SFTConcreteControl.sol";
import "./IBaseSFTConcrete.sol";

abstract contract BaseSFTConcreteUpgradeable is IBaseSFTConcrete, SFTConcreteControl {

	modifier onlyDelegateOwner {
		require(_msgSender() == OwnControl(delegate()).owner(), "only delegate owner");
		_;
	}

	function __BaseSFTConcrete_init() internal onlyInitializing {
		__SFTConcreteControl_init();
	}

	function isSlotValid(uint256 slot_) external view virtual override returns (bool) {
		return _isSlotValid(slot_);
	}

	function _isSlotValid(uint256 slot_) internal view virtual returns (bool);

	uint256[50] private __gap;
}