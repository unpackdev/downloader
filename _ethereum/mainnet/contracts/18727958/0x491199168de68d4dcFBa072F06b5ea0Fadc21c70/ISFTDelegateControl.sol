//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISFTDelegateControl {
	event NewConcrete(address old_, address new_);

	function concrete() external view returns (address);
	function setConcreteOnlyAdmin(address newConcrete_) external;
}