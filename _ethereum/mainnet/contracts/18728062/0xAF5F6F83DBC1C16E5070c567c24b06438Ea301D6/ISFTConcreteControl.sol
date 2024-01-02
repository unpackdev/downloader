// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface ISFTConcreteControl {
	event NewDelegate(address old_, address new_);

	function setDelegate(address newDelegate_) external;
	function delegate() external view returns (address);
}