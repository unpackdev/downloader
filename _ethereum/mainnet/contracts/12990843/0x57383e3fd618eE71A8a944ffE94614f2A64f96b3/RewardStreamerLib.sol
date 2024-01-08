// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Math.sol";
import "./TokenHelper.sol";

library RewardStreamerLib {
	struct RewardStreamInfo {
		RewardStream[] rewardStreams;
		uint256 deployedAtBlock;
		address rewardToken;
	}

	struct RewardStream {
		uint256[] periodRewards;
		uint256[] periodEnds;
		uint256 rewardStreamCursor;
	}

	/**
	* @notice Will setup the token to use for reward
	* @param rewardTokenAddress The reward token address
	*/
	function setRewardToken(RewardStreamInfo storage rewardStreamInfo, address rewardTokenAddress) public {
		rewardStreamInfo.rewardToken = address(rewardTokenAddress);
	}

	/**
	* @notice Will create a new reward stream
	* @param rewardStreamIndex The reward index
	* @param rewardPerBlock The amount of tokens rewarded per block
	* @param rewardLastBlock The last block of the period
	*/
	function addRewardStream(
		RewardStreamInfo storage rewardStreamInfo,
		uint256 rewardStreamIndex,
		uint256 rewardPerBlock,
		uint256 rewardLastBlock
	)
		public
		returns (uint256)
	{
		// e.g. current length = 0
		require(rewardStreamIndex <= rewardStreamInfo.rewardStreams.length, "RewardStreamer: you cannot skip an index");

		uint256 tokensInReward;

		if(rewardStreamInfo.rewardStreams.length > rewardStreamIndex) {
			RewardStream storage rewardStream = rewardStreamInfo.rewardStreams[rewardStreamIndex];
			uint256[] storage periodEnds = rewardStream.periodEnds;

			uint periodStart = periodEnds.length == 0
				? rewardStreamInfo.deployedAtBlock
				: periodEnds[periodEnds.length - 1];

			require(periodStart < rewardLastBlock, "RewardStreamer: periodStart must be smaller than rewardLastBlock");

			rewardStreamInfo.rewardStreams[rewardStreamIndex].periodEnds.push(rewardLastBlock);
			rewardStreamInfo.rewardStreams[rewardStreamIndex].periodRewards.push(rewardPerBlock);

			tokensInReward = (rewardLastBlock - periodStart) * rewardPerBlock;
		} else {
			RewardStream memory rewardStream;

			uint periodStart = rewardStreamInfo.deployedAtBlock;
			require(periodStart < rewardLastBlock, "RewardStreamer: periodStart must be smaller than rewardLastBlock");

			rewardStreamInfo.rewardStreams.push(rewardStream);
			rewardStreamInfo.rewardStreams[rewardStreamIndex].periodEnds.push(rewardLastBlock);
			rewardStreamInfo.rewardStreams[rewardStreamIndex].periodRewards.push(rewardPerBlock);

			tokensInReward = (rewardLastBlock - periodStart) * rewardPerBlock;
		}

		TokenHelper.ERC20TransferFrom(address(rewardStreamInfo.rewardToken), msg.sender, address(this), tokensInReward);

		return tokensInReward;
	}

	/**
	* @notice Get the rewards for a period
	* @param fromBlock the block number from which the reward is calculated
	* @param toBlock the block number till which the reward is calculated
	* @return (uint256) the total reward
	*/
	function unsafeGetRewardsFromRange(
		RewardStreamInfo storage rewardStreamInfo,
		uint fromBlock,
		uint toBlock
	)
		public
		view
		returns (uint256)
	{
		require(tx.origin == msg.sender, "StakingReward: unsafe function for contract call");

		uint256 currentReward;

		for(uint256 i; i < rewardStreamInfo.rewardStreams.length; i++) {
			currentReward = currentReward + iterateRewards(
				rewardStreamInfo,
				i,
				Math.max(fromBlock, rewardStreamInfo.deployedAtBlock),
				toBlock,
				0
			);
		}

		return currentReward;
	}

	/**
	* @notice Iterate the rewards
	* @param rewardStreamIndex the index of the reward stream
	* @param fromBlock the block number from which the reward is calculated
	* @param toBlock the block number till which the reward is calculated
	* @param rewardIndex the reward index
	* @return (uint256) the calculate reward
	*/
	function iterateRewards(
		RewardStreamInfo storage rewardStreamInfo,
		uint256 rewardStreamIndex,
		uint fromBlock,
		uint toBlock,
		uint256 rewardIndex
	)
		public
		view
		returns (uint256)
	{
		// the start block is bigger than
		if(rewardIndex >= rewardStreamInfo.rewardStreams[rewardStreamIndex].periodRewards.length) {
			return 0;
		}

		uint currentPeriodEnd = rewardStreamInfo.rewardStreams[rewardStreamIndex].periodEnds[rewardIndex];
		uint currentPeriodReward = rewardStreamInfo.rewardStreams[rewardStreamIndex].periodRewards[rewardIndex];

		uint256 totalReward = 0;

		// what's the lowest block in current period?
		uint currentPeriodStart = rewardIndex == 0
			? rewardStreamInfo.deployedAtBlock
			: rewardStreamInfo.rewardStreams[rewardStreamIndex].periodEnds[rewardIndex - 1];
		// is the fromBlock included in period?
		if(fromBlock <= currentPeriodEnd) {
			uint256 lower = Math.max(fromBlock, currentPeriodStart);
			uint256 upper = Math.min(toBlock, currentPeriodEnd);

			uint256 blocksInPeriod = upper - lower;
			totalReward = blocksInPeriod * currentPeriodReward;
		} else {
			return iterateRewards(
				rewardStreamInfo,
				rewardStreamIndex,
				fromBlock,
				toBlock,
				rewardIndex + 1
			);
		}

		if(toBlock > currentPeriodEnd) {
			// we need to move to next reward period
			totalReward += iterateRewards(
				rewardStreamInfo,
				rewardStreamIndex,
				fromBlock,
				toBlock,
				rewardIndex + 1
			);
		}

		return totalReward;
	}

	/**
	* @notice Iterate the rewards and updates the cursor
	* @notice NOTE: once the cursor is updated, the next call will start from the cursor
	* @notice making it impossible to calculate twice the reward in a period
	* @param rewardStreamInfo the struct holding  current reward info
	* @param fromBlock the block number from which the reward is calculated
	* @param toBlock the block number till which the reward is calculated
	* @return (uint256) the calculated reward
	*/
	function getRewardAndUpdateCursor (
		RewardStreamInfo storage rewardStreamInfo,
		uint256 fromBlock,
		uint256 toBlock
	)
		public
		returns (uint256)
	{
		uint256 currentReward;

		for(uint256 i; i < rewardStreamInfo.rewardStreams.length; i++) {
			currentReward = currentReward + iterateRewardsWithCursor(
				rewardStreamInfo,
				i,
				Math.max(fromBlock, rewardStreamInfo.deployedAtBlock),
				toBlock,
				rewardStreamInfo.rewardStreams[i].rewardStreamCursor
			);
		}

		return currentReward;
	}

	function bumpStreamCursor(
		RewardStreamInfo storage rewardStreamInfo,
		uint256 rewardStreamIndex
	)
		public
	{
		// this step is important to avoid going out of index
		if(rewardStreamInfo.rewardStreams[rewardStreamIndex].rewardStreamCursor < rewardStreamInfo.rewardStreams[rewardStreamIndex].periodRewards.length) {
			rewardStreamInfo.rewardStreams[rewardStreamIndex].rewardStreamCursor = rewardStreamInfo.rewardStreams[rewardStreamIndex].rewardStreamCursor + 1;
		}
	}

	function iterateRewardsWithCursor(
		RewardStreamInfo storage rewardStreamInfo,
		uint256 rewardStreamIndex,
		uint fromBlock,
		uint toBlock,
		uint256 rewardPeriodIndex
	)
		public
		returns (uint256)
	{
		if(rewardPeriodIndex >= rewardStreamInfo.rewardStreams[rewardStreamIndex].periodRewards.length) {
			return 0;
		}

		uint currentPeriodEnd = rewardStreamInfo.rewardStreams[rewardStreamIndex].periodEnds[rewardPeriodIndex];
		uint currentPeriodReward = rewardStreamInfo.rewardStreams[rewardStreamIndex].periodRewards[rewardPeriodIndex];

		uint256 totalReward = 0;

		// what's the lowest block in current period?
		uint currentPeriodStart = rewardPeriodIndex == 0
			? rewardStreamInfo.deployedAtBlock
			: rewardStreamInfo.rewardStreams[rewardStreamIndex].periodEnds[rewardPeriodIndex - 1];

		// is the fromBlock included in period?
		if(fromBlock <= currentPeriodEnd) {
			uint256 lower = Math.max(fromBlock, currentPeriodStart);
			uint256 upper = Math.min(toBlock, currentPeriodEnd);

			uint256 blocksInPeriod = upper - lower;

			totalReward = blocksInPeriod * currentPeriodReward;
		} else {
			// the fromBlock passed this reward period, we can start
			// skipping it for next reads
			bumpStreamCursor(rewardStreamInfo, rewardStreamIndex);

			return iterateRewards(rewardStreamInfo, rewardStreamIndex, fromBlock, toBlock, rewardPeriodIndex + 1);
		}

		if(toBlock > currentPeriodEnd) {
			// we need to move to next reward period
			totalReward += iterateRewards(rewardStreamInfo, rewardStreamIndex, fromBlock, toBlock, rewardPeriodIndex + 1);
		}

		return totalReward;
	}
}