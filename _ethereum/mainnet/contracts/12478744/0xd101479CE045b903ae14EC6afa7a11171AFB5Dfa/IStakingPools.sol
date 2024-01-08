// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

import "./IERC20.sol";

interface IStakingPools {
	function reward() external view returns (IERC20);

	function rewardRate() external view returns (uint256);

	function totalRewardWeight() external view returns (uint256);

	function getPoolToken(uint256 _poolId) external view returns (IERC20);

	function getStakeTotalUnclaimed(address _account, uint256 _poolId) external view returns (uint256);
}
