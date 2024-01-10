// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./IERC20.sol";

interface ISpoolStaking {
	/* ========== EVENTS ========== */

	event Staked(address indexed user, uint256 amount);

	event StakedFor(address indexed stakedFor, address indexed stakedBy, uint256 amount);

	event Unstaked(address indexed user, uint256 amount);
	
	event RewardCompounded(address indexed user, uint256 reward);
	
	event VoRewardCompounded(address indexed user, uint256 reward);

	event RewardPaid(IERC20 token, address indexed user, uint256 reward);

	event VoSpoolRewardPaid(IERC20 token, address indexed user, uint256 reward);

	event RewardAdded(IERC20 indexed token, uint256 amount, uint256 duration);

	event RewardUpdated(IERC20 indexed token, uint256 amount, uint256 leftover, uint256 duration, uint32 periodFinish);

	event RewardRemoved(IERC20 indexed token);

	event PeriodFinishUpdated(IERC20 indexed token, uint32 periodFinish);

	event CanStakeForSet(address indexed account, bool canStakeFor);
}
