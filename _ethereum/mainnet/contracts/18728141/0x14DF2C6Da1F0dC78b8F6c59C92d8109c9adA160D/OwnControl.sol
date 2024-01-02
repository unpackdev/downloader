// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AdminControl.sol";

abstract contract OwnControl is AdminControl {
	event NewOwner(address oldOwner, address newOwner);

	address public owner;

	modifier onlyOwner() {
		require(owner == _msgSender(), "only owner");
		_;
	}

	function __OwnControl_init(address owner_) internal onlyInitializing {
		__OwnControl_init_unchained(owner_);
		__AdminControl_init_unchained(_msgSender());
	}

	function __OwnControl_init_unchained(address owner_) internal onlyInitializing {
		_setOwner(owner_);
	}

	function setOwnerOnlyAdmin(address newOwner_) public onlyAdmin {
		_setOwner(newOwner_);
	}

	function _setOwner(address newOwner_) internal {
		require(newOwner_ != address(0), "Owner address connot be 0");
		emit NewOwner(owner, newOwner_);
		owner = newOwner_;
	}

	uint256[49] private __gap;
}