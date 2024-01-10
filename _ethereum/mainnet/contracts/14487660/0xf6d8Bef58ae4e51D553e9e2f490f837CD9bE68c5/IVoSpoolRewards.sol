// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IVoSpoolRewards {
	/* ========== FUNCTIONS ========== */

	function updateRewards(address user) external returns (uint256);

	function flushRewards(address user) external returns (uint256);

	/* ========== EVENTS ========== */

	event RewardRateUpdated(uint8 indexed fromTranche, uint8 indexed toTranche, uint112 rewardPerTranche);

	event RewardEnded(
		uint256 indexed rewardRatesIndex,
		uint8 indexed fromTranche,
		uint8 indexed toTranche,
		uint8 currentTrancheIndex
	);

	event UserRewardUpdated(address indexed user, uint8 lastRewardRateIndex, uint248 earned);
}
