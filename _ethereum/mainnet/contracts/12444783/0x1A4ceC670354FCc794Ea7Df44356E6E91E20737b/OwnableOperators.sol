// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";

abstract contract OwnableOperators is OwnableUpgradeable {
	mapping(address => bool) private _operators;

	function __OwnableOperators_init() internal {
		__Ownable_init();
		_addOperator(msg.sender);
	}

	modifier onlyOperator() {
		require(isOperator(msg.sender), 'Role: not Operator');
		_;
	}

	function isOperator(address address_) public view returns (bool) {
		return _operators[address_] == true;
	}

	function addOperators(address[] calldata operators) external onlyOwner {
		for (uint256 i; i < operators.length; i++) {
			_addOperator(operators[i]);
		}
	}

	function removeOperators(address[] calldata operators) external onlyOwner {
		for (uint256 i; i < operators.length; i++) {
			_operators[operators[i]] = false;
		}
	}

	function _addOperator(address operator) internal {
		require(operator != address(0), 'Role: invalid Operator');
		_operators[operator] = true;
	}
}
