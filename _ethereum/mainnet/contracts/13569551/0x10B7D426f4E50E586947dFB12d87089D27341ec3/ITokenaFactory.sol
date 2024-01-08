// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ITokenaFactory {
	function getFeeTaker() external view returns (address);

	function getFeePercentage() external view returns (uint256);

	function getDelta() external view returns (uint256);

	function whitelistAddress(address user) external view returns (bool);
}
