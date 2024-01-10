// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./IERC20.sol";

interface IRewardDistributor {
	/* ========== FUNCTIONS ========== */

	function payRewards(
		address account,
		IERC20[] memory tokens,
		uint256[] memory amounts
	) external;

	function payReward(
		address account,
		IERC20 token,
		uint256 amount
	) external;

	/* ========== EVENTS ========== */

	event RewardPaid(IERC20 token, address indexed account, uint256 amount);
	event RewardRetrieved(IERC20 token, address indexed account, uint256 amount);
	event DistributorUpdated(address indexed user, bool set);
	event PauserUpdated(address indexed user, bool set);
}
