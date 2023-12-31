// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title WithOperators
/// @author dev by @dievardump
/// @notice This contract adds operators management
abstract contract WithOperators {
	error NotAuthorized();

	/// @notice the address of the minter module
	mapping(address => bool) public operators;

	modifier onlyOperator() virtual {
		if (!operators[msg.sender]) {
			revert NotAuthorized();
		}
		_;
	}

	/// @notice Allows to add operators to this contract
	/// @param operatorsList the new operators to add
	/// @param isOperator if the operators should be added or removed
	function _setOperators(address[] memory operatorsList, bool isOperator) internal virtual {
		uint256 length = operatorsList.length;
		for (uint256 i; i < length; i++) {
			operators[operatorsList[i]] = isOperator;
		}
	}
}
