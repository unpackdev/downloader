
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./Ownable.sol";

abstract contract Operable is Ownable {
	mapping(address => bool) public operators;
	address[] public operatorsList;

	constructor(address operator_) {
		operators[operator_] = true;
		operatorsList.push(operator_);	
		emit SetOperator(operator_, true);	
	}

	function setOperator(address operator_, bool state_) public onlyOperator {
		require(operators[operator_] != state_, "Already set");
		operators[operator_] = state_;
		if (state_) {
			operatorsList.push(operator_);
		} else {
			for (uint256 i = 0; i < operatorsList.length; i++) {
				if (operatorsList[i] == operator_) {
					operatorsList[i] = operatorsList[operatorsList.length - 1];
					operatorsList.pop();
					break;
				}
			}
		}
		emit SetOperator(operator_, state_);
	}

	function operatorsCount() public view returns (uint256) {
		return operatorsList.length;
	}

	modifier onlyOperator() {
		require(operators[msg.sender] || msg.sender == owner(), "Sender is not the operator or owner");
		_;
	}
	event SetOperator(address operator, bool state);
}