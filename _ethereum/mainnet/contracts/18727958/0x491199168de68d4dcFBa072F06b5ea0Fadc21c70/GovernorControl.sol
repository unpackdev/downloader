// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AdminControl.sol";

abstract contract GovernorControl is AdminControl {
	event NewGovernor(address oldGovernor, address newGovernor);

	address public governor;

	modifier onlyGovernor() {
		require(governor == _msgSender(), "only governor");
		_;
	}

	function __GovernorControl_init(address governor_) internal onlyInitializing {
		__GovernorControl_init_unchained(governor_);
		__AdminControl_init_unchained(_msgSender());
	}

	function __GovernorControl_init_unchained(address governor_) internal onlyInitializing {
		_setGovernor(governor_);
	}

	function setGovernorOnlyAdmin(address newGovernor_) public onlyAdmin {
		_setGovernor(newGovernor_);
	}

	function _setGovernor(address newGovernor_) internal {
		require(newGovernor_ != address(0), "Governor address connot be 0");
		emit NewGovernor(governor, newGovernor_);
		governor = newGovernor_;
	}

	uint256[49] private __gap;
}