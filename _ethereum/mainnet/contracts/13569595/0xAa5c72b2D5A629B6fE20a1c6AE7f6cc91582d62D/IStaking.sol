// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IStaking {
	struct ProjectInfo {
		string name;
		string link;
		uint256 themeId;
	}

	function initialize(
		address stakedToken,
		address[] memory rewardToken,
		uint256[] memory rewardTokenAmounts,
		uint256 startBlock,
		uint256 endBlock,
		ProjectInfo calldata info,
		address admin
	) external;
}
