// SPDX-License-Identifier: MIT
pragma solidity >=0.6.5 <0.8.0;

import "./IERC20.sol";

interface IHarvestFarm {
	function rewardToken() external view returns (address);

	function lpToken() external view returns (address);

	function getReward() external;

	function stake(uint256 amount) external;

	function withdraw(uint256) external;

	function rewards(address) external returns (uint256);

	function balanceOf(address) external view returns (uint256);
}
