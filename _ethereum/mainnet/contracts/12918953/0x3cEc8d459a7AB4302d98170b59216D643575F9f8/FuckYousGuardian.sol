// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

import "./DiamondLib.sol";
import "./EternalLib.sol";
import "./IERC173.sol";

// The OwnershipFacet contract
//
// This contract keeps track of the ownership.

contract FuckYousGuardian is IERC173 {
	function transferOwnership(address _newOwner) external override {
		DiamondLib.enforceIsContractOwner();
		DiamondLib.setContractOwner(_newOwner);
	}

	function owner() external override view returns (address owner_) {
		owner_ = DiamondLib.contractOwner();
	}

	function setFuckYousAddress(address _address) external {
		DiamondLib.enforceIsContractOwner();

		EternalLib.setFuckYousAddress(_address);
	}

}
