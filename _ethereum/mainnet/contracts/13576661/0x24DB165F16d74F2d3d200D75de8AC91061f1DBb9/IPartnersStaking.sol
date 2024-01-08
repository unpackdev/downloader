// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

interface IPartnersStaking {
	event RewardsSet(
		uint256 rewardPerBlock,
		uint256 firstBlockWithReward,
		uint256 lastBlockWithReward
	);
	event Staked(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RewardPaid(address indexed user, uint256 reward);
	event RewardRestaked(address indexed user, uint256 reward, uint256 stakingTokens);
	event RewardTokensRecovered(uint256 amount);

	function initialize(
		address _stakingToken,
		address _rewardsToken,
		address _owner
	) external;

	function setRewards(
		uint256 _rewardPerBlock,
		uint256 _startingBlock,
		uint256 _blocksAmount
	) external;

	function recoverNonLockedRewardTokens() external;

	function pause() external;

	function unpause() external;

	function exit() external;

	function stake(uint256 _amount) external;

	function withdraw(uint256 _amount) external;

	function getReward() external;

	function blocksWithRewardsPassed() external view returns (uint256);

	function rewardPerToken() external view returns (uint256);

	function earned(address _account) external view returns (uint256);
}
