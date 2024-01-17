// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Address.sol";
import "./Ownable.sol";

contract OwnableExtended is Ownable {
	mapping(address => bool) internal operatorApprovals;

	constructor() {
		operatorApprovals[msg.sender] = true;
	}

	modifier onlyOperator() virtual {
		require(operatorApprovals[_msgSender()], "Not operator");
		_;
	}

	function setOperator(address operator) external virtual onlyOperator {
		operatorApprovals[operator] = true;
	}

	function deleteOperator(address operator) external virtual onlyOperator {
		delete operatorApprovals[operator];
	}

	function isOperator(address operator) public view returns (bool) {
		return operatorApprovals[operator];
	}

	function withdraw(address beneficiary, uint amount) public virtual onlyOwner {
		Address.sendValue(payable(beneficiary), amount);
	}
}
