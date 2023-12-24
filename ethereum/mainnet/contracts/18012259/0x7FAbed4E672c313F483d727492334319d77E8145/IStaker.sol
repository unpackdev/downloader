// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

interface IStaker {
	function pending(address) external view returns (uint);
	function claimAndDistribute() external;
}
