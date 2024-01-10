// SPDX-License-Identifier: MIT
pragma solidity >=0.6.5 <0.8.0;

interface IHarvestVaultAdapter {
	function totalValue() external view returns (uint256);

	function deposit(uint256) external;

	function withdraw(address, uint256) external;

	function token() external view returns (address);

	function lpToken() external view returns (address);

	function lpTokenInFarm() external view returns (uint256);

	function stake(uint256) external;

	function unstake(uint256) external;

	function claim() external;
}
