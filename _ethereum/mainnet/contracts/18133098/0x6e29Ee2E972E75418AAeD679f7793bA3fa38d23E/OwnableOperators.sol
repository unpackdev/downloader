// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./Ownable.sol";
import "./WithOperators.sol";

/// @title OwnableOperators
/// @author dev by @dievardump
/// @notice This contract adds ownable & operators management
abstract contract OwnableOperators is Ownable, WithOperators {
	modifier onlyOperator() virtual override {
		if (msg.sender != owner()) {
			if (!operators[msg.sender]) {
				revert NotAuthorized();
			}
		}
		_;
	}

	/// @notice Allows to add operators to this contract
	/// @param operatorsList the new operators to add
	/// @param isOperator if the operators should be added or removed
	function setOperators(address[] memory operatorsList, bool isOperator) public onlyOwner {
		_setOperators(operatorsList, isOperator);
	}
}
