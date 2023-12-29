// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

interface IStaking {
	function deposit(address, uint) external;
	function claim() external;
	function withdraw() external;
	function pending(address who) external view returns (uint);
}
