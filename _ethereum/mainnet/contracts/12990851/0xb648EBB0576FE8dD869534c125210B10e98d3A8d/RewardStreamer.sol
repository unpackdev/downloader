// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RewardStreamerLib.sol";


/// @title A Staking smart contract
/// @author Valerio Leo @valerioHQ
contract RewardStreamer {

	RewardStreamerLib.RewardStreamInfo public rewardStreamInfo;

	event RewardStreamAdded(uint256 rewardPerBlock, uint256 rewardLastBlock, uint256 rewardInStream);

	function rewardToken() public view returns (address) {return address(rewardStreamInfo.rewardToken);}

	/**
	* @notice Will setup the token to use for reward
	* @param rewardTokenAddress The reward token address
	*/
	function _setRewardToken(address rewardTokenAddress) internal {
		RewardStreamerLib.setRewardToken(rewardStreamInfo, rewardTokenAddress);
	}

	/**
	* @notice Will create a new reward stream
	* @param rewardStreamIndex The reward index
	* @param rewardPerBlock The amount of tokens rewarded per block
	* @param rewardLastBlock The last block of the period
	*/
	function _addRewardStream(uint256 rewardStreamIndex, uint256 rewardPerBlock, uint256 rewardLastBlock) internal {
		uint256 tokensInReward = RewardStreamerLib.addRewardStream(
			rewardStreamInfo,
			rewardStreamIndex,
			rewardPerBlock,
			rewardLastBlock
		);

		emit RewardStreamAdded(rewardPerBlock, rewardLastBlock, tokensInReward);
	}
}
