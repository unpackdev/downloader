//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IFracTokenVault {
	function updateCurator(address curator) external;

	function transfer(address recipient, uint256 amount) external returns (bool);
}
