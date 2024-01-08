// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Math.sol";

import "./INFTRarityRegister.sol";

import "./IRaffleTicket.sol";
import "./RewardStreamerLib.sol";

import "./TokenHelper.sol";

library StakingLib {
  // **************************
	// **| StakingLib section |**
  // **************************

	struct StakingInfo {
		uint256 historyStartBlock; // this is set only when we deploy the contract
		uint256 historyEndBlock; // it starts and finishes in the same block (so length is 0)
		uint256 historyAverageReward; // how many reward tokens (in Wei) we give PER TOKEN STAKED PER BLOCK
		uint256 historyRewardPot; // the tokens unclaimed from history

		uint256 totalCurrentlyStaked; // the actual amount of $BURP tokens sent from users
		uint256 totalStakingUnits; // sum of all user stake shares

		uint256 totalDistributedRewards; // sum of all distributed rewards, mainly helpful for testing

		uint256[] locks;
		uint256[] locksMultiplier;

		uint256 ticketsMintingRatio;
		uint256 ticketsMintingChillPeriod;

		address ticket;
		address rarityRegister;
	}

	/**
	* @notice Will get the lock duration from the stake bytes data
	* @dev the bytes should contain the index of the lock in the first 32 bytes
	* @dev the index should be < locks.length
	* @param data bytes from the stake action
	* @return uint256 The duration of the lock (time for which the stake will be locked)
	*/
	function getLockDuration(StakingInfo storage stakingInfo, bytes memory data) public view returns (uint256, uint256) {
		require(data.length >= 32, 'Stake: data should by at least 32 bytes');

		uint256 lengthIndex = getStakeIndexFromCalldata(data);

		require(lengthIndex < stakingInfo.locks.length, 'Stake: lock index out of bounds');

		return (stakingInfo.locks[lengthIndex], lengthIndex);
	}

	/**
	* @notice Will calculate the current period length
	* @return (uint256) The current period length
	*/
	function getCurrentPeriodLength(StakingInfo storage stakingInfo) public view returns(uint256) {
		return uint256(block.number) - stakingInfo.historyEndBlock;
	}

	/**
	* @notice Will calculate the current period length optionally including the last block
	* @param excludeLast a flag that indicates to include the last block or not
	* @return (uint256) The current period length
	*/
	function getCurrentPeriodLength(StakingInfo storage stakingInfo, bool excludeLast) public view returns(uint256) {
		return excludeLast ? getCurrentPeriodLength(stakingInfo) - 1 : getCurrentPeriodLength(stakingInfo);
	}

	/**
	* @notice Will calculate the history length in blocks
	* @return (uint256) The history length
	*/
	function getHistoryLength(StakingInfo storage stakingInfo) public view returns (uint256){
		return stakingInfo.historyEndBlock - stakingInfo.historyStartBlock;
	}

	/**
	* @notice Calculate the average reward for the current period
	* @param stakingInfo the struct containing staking info
	* @param totalReward the total reward in current period
	* @param excludeLast whether or not exclude the last block
	* @return (uint256) number of blocks in history
	*/
	function getCurrentPeriodAverageReward(
		StakingInfo storage stakingInfo,
		uint256 totalReward,
		bool excludeLast
	)
		public
		view
		returns(uint256)
	{
		if (stakingInfo.totalStakingUnits == 0) {
			return 0;
		}

		uint256 currentPeriodLength = getCurrentPeriodLength(stakingInfo, excludeLast);
		if(currentPeriodLength == 0 ) {
			return 0;
		}

		return totalReward
			* (10**18)
			/ (stakingInfo.totalStakingUnits)
			/ (currentPeriodLength);
	}

	/**
	* @notice Calculate the total generated reward for a period
	* @param _block the current block
	* @param historyStartBlock the first history block
	* @param rewardPerBlock the amount of tokens rewarded per block
	* @return (uint256) number of blocks in history
	*/
	function totalGeneratedReward(uint256 _block, uint256 historyStartBlock, uint256 rewardPerBlock) public pure returns(uint256) {
		return (_block - historyStartBlock) * rewardPerBlock;
	}

	/**
	* @notice Calculate the reward from current period
	* @param totalRewardInCurrentPeriod the total reward from current period
	* @param totalStakingUnits sum of all user stake shares
	* @return (uint256) the calculated reward
	*/
	function _stakerRewardFromCurrentPeriod(
		uint256 totalRewardInCurrentPeriod,
		uint256 stakerBalance,
		uint256 totalStakingUnits
	)
		private
		pure
		returns(uint256)
	{
		return totalRewardInCurrentPeriod
			* stakerBalance
			/ totalStakingUnits;
	}

	/**
	* @notice Calculate the reward from current period
	* @return (uint256) the calculated reward
	*/
	function getStakerRewardFromCurrentPeriod(
		RewardStreamerLib.RewardStreamInfo storage rewardStreamInfo,
		StakingInfo storage stakingInfo,
		UserStake[] storage userStakes,
		uint256 stakeIndex
	)
		public
		view
		returns(uint256)
	{
		if (stakeIndex >= userStakes.length) {
			return 0;
		}

		uint256 stakerBalance = userStakes[stakeIndex].stakingUnits;
		uint256	totalRewardInCurrentPeriod = RewardStreamerLib.unsafeGetRewardsFromRange(
			rewardStreamInfo,
			stakingInfo.historyEndBlock,
			block.number
		);

		return _stakerRewardFromCurrentPeriod(
			totalRewardInCurrentPeriod,
			stakerBalance,
			stakingInfo.totalStakingUnits
		);
	}

	/**
	* @notice Calculate the reward from current period
	* @return (uint256) the calculated reward
	*/
	function getStakerRewardFromCurrentPeriodAndUpdateCursor(
		RewardStreamerLib.RewardStreamInfo storage rewardStreamInfo,
		StakingInfo storage stakingInfo,
		UserStake[] storage userStakes,
		uint256 stakeIndex
	)
		private
		returns(uint256)
	{
		if (stakeIndex >= userStakes.length) {
			return 0;
		}

		uint256 stakerBalance = userStakes[stakeIndex].stakingUnits;
		uint256	totalRewardInCurrentPeriod = RewardStreamerLib.getRewardAndUpdateCursor(
			rewardStreamInfo,
			stakingInfo.historyEndBlock,
			block.number - 1
		);


		return _stakerRewardFromCurrentPeriod(
			totalRewardInCurrentPeriod,
			stakerBalance,
			stakingInfo.totalStakingUnits
		);
	}

	/**
	* @notice Will calculate and return the total reward user has accumulated till now for a specific stake
	* @param stakeIndex the index of the stake
	* @return (uint256) The total rewards accumulated till now
	*/
	function getStakerReward(
		RewardStreamerLib.RewardStreamInfo storage rewardStreamInfo,
		StakingInfo storage stakingInfo,
		UserStake[] storage userStakes,
		uint256 stakeIndex
	)
		public
		view
		returns (uint256)
	{
		uint256 currentPeriodReward = getStakerRewardFromCurrentPeriod(rewardStreamInfo, stakingInfo, userStakes, stakeIndex);
		uint256 historyPeriodReward = getStakerRewardFromHistory(stakingInfo, userStakes, stakeIndex);

		return currentPeriodReward + historyPeriodReward;
	}

	/**
	* @notice Will calculate and return the total reward user has accumulated till now for a specific stake
	* @param stakeIndex the index of the stake
	* @return (uint256) The total rewards accumulated till now
	*/
	function _getStakerReward(
		RewardStreamerLib.RewardStreamInfo storage rewardStreamInfo,
		StakingInfo storage stakingInfo,
		UserStake[] storage userStakes,
		uint256 stakeIndex
	)
		private
		returns (uint256)
	{
		uint256 currentPeriodReward = getStakerRewardFromCurrentPeriodAndUpdateCursor(rewardStreamInfo, stakingInfo, userStakes, stakeIndex);
		uint256 historyPeriodReward = getStakerRewardFromHistory(stakingInfo, userStakes, stakeIndex);

		return currentPeriodReward + historyPeriodReward;
	}

	/**
	* @notice Creates a stake instance for the staker
	* @notice MUST trigger Staked event
	* @dev The NFT should be in the rarityRegister
	* @dev For each stake you can have only one NFT staked
	* @param amountStaked the number of tokens to be staked
	* @param blockNumber the block number at which the stake is created
	* @param lockDuration the duration for which the tokens will be locked
	*/
	function addStake(
		StakingInfo storage stakingInfo,
		UserStake[] storage userStakes,
		uint256 amountStaked,
		uint256 stakingUnits,
		uint256 blockNumber,
		uint256 lockDuration
	)
		private
	{
		userStakes.push(UserStake({
				amountStaked: amountStaked,
				stakingUnits: stakingUnits,
				enteredAtBlock: blockNumber,
				historyAverageRewardWhenEntered: stakingInfo.historyAverageReward,
				ticketsMintingRatioWhenEntered: stakingInfo.ticketsMintingRatio,
				ticketsMintingChillPeriodWhenEntered: stakingInfo.ticketsMintingChillPeriod,
				lockedTill: blockNumber + lockDuration,
				rewardCredit: 0,
				ticketsMinted: 0,
				userStakedToken: StakingLib.UserStakedToken({
					tokenAddress: address(0),
					tokenId: 0
				})
			})
		);
	}

	/**
	* @notice Allows user to stake tokens
	* @notice Optionally user can stake a NFT token for extra reward
	* @dev Users wil be able to unstake only after the lock durationn has pased.
	* @dev The lock duration in the data bytes is required, its the index of the locks array
	* Should be the fist 32 bytes in the bytes array
	* @param amount the inumber of tokens to be staked
	* @param data the bytes containing extra information about the staking
	* lock duration index: fist 32 bytes (Number) - Required
	* NFT address: next 20 bytes (address)
	* NFT tokenId: next 32 bytes (Number)
	*/
	function stake(
		RewardStreamerLib.RewardStreamInfo storage rewardStreamInfo,
		StakingInfo storage stakingInfo,
		UserStake[] storage userStakes,
		address staker,
		uint256 amount,
		bytes calldata data
	)
		public
	{
			(uint256 lockDuration, uint256 lockIndex) = getLockDuration(stakingInfo, data);

			TokenHelper.ERC20TransferFrom(address(rewardStreamInfo.rewardToken), msg.sender, address(this), amount);

			updateHistoryValues(rewardStreamInfo, stakingInfo);

			uint256 durationMultiplier = stakingInfo.locksMultiplier[lockIndex];

			// when staking without any multiplier, staking units and amount are identical
			stakingInfo.totalStakingUnits = stakingInfo.totalStakingUnits + applyPercent(amount, durationMultiplier);
			stakingInfo.totalCurrentlyStaked = stakingInfo.totalCurrentlyStaked + amount;

			addStake(stakingInfo, userStakes, amount, applyPercent(amount, durationMultiplier), block.number, lockDuration);

			if (data.length >= 84) { // [32, 20. 32] == [index, address, tokenId]
				addNftToStake(
					rewardStreamInfo,
					stakingInfo,
					userStakes,
					userStakes.length - 1,
					getTokenAddressFromCalldata(data),
					getTokenIdFromCalldata(data)
				);
			}
			claimTickets(
				stakingInfo.ticket,
				userStakes[userStakes.length - 1], // last stake just created
				staker
			);
	}

	/**
	* @notice Calculate the new history reward pot
	* @param oldHistoryRewardPot the old history reward pot
	* @param totalRewardInCurrentPeriod the total reward from current period
	* @param stakerReward the staker reward
	* @return (uint256) the new history reward pot
	*/
	function historyRewardPot(
		uint256 oldHistoryRewardPot,
		uint256 totalRewardInCurrentPeriod,
		uint256 stakerReward
	) public pure returns(uint256) {
		return oldHistoryRewardPot
			+ totalRewardInCurrentPeriod
			- stakerReward;
	}

	/**
	* @notice Will parse bytes data to get an uint256
	* @param data bytes data
	* @param from from where to start the parsing
	*/
	function parse32BytesToUint256(bytes memory data, uint256 from) public pure returns (uint256 parsed){
		assembly {parsed := mload(add(add(data, from), 32))}
	}

	/**
	* @notice Will parse bytes data to get an address
	* @param data bytes data
	* @param from from where to start the parsing
	*/
	function parseBytesToAddress(bytes memory data, uint256 from) public pure returns (address parsed){
		assembly {parsed := mload(add(add(data, from), 20))}
	}

	/**
	* @notice Will parse the stake bytes data to get the stake index
	* @dev [(index 32 bytes), (nft address 20 bytes), (tokenId 32 bytes)]
	* @param data bytes from the stake action
	* @return (uint256) the parsed index
	*/
	function getStakeIndexFromCalldata(bytes memory data) public pure returns (uint256) {
		return parse32BytesToUint256(data, 0);
	}

	/**
	* @notice Will parse the stake bytes data to get the NFT address
	* @dev [(index 32 bytes), (nft address 20 bytes), (tokenId 32 bytes)]
	* @param data bytes from the stake action
	* @return (address) the parsed address
	*/
	function getTokenAddressFromCalldata(bytes memory data) public pure returns (address) {
		return parseBytesToAddress(data, 32);
	}

	/**
	* @notice Will parse the stake bytes data to get the NFT tokeId
	* @dev [(index 32 bytes), (nft address 20 bytes), (tokenId 32 bytes)]
	* @param data bytes from the stake action
	* @return (uint256) the parsed tokenId
	*/
	function getTokenIdFromCalldata(bytes memory data) public pure returns (uint256) {
		return parse32BytesToUint256(data, 52);
	}

	/**
	* @notice Will apply a percentage to a number
	* @param number The number to multiply
	* @param percent The percentage to apply
	* @return (uint256) the operation result
	*/
	function applyPercent(uint256 number, uint256 percent) public pure returns (uint256) {
		return number * percent / 100;
	}

	/**
	* @notice Calculates the new History Average Reward
	* @dev this is called **before** we update history end block
	* @return uint256 The calculated newHistoryAverageReward
	*/
	function getNewHistoryAverageReward(
		uint256 currentPeriodLength,
		uint256 currentPeriodAverageReward,
		uint256 currentHistoryLength,
		uint256 historyStartBlock,
		uint256 historyAverageReward
	) public view returns (uint256) {
		uint256 blockNumber = block.number;
		uint256 newHistoryLength = uint256(blockNumber)- 1 - historyStartBlock;

		uint256 fromCurrent = currentPeriodLength * currentPeriodAverageReward;
		uint256 fromHistory = currentHistoryLength * historyAverageReward;

		uint256 newHistoryAverageReward = (
			fromCurrent + fromHistory
		)
		/ newHistoryLength;

		return newHistoryAverageReward;
	}

	function updateHistoryValues(
		RewardStreamerLib.RewardStreamInfo storage rewardStreamInfo,
		StakingInfo storage stakingInfo
	)
		public
	{
		uint256 totalRewardInCurrentPeriod = RewardStreamerLib.getRewardAndUpdateCursor(
			rewardStreamInfo,
			stakingInfo.historyEndBlock,
			block.number - 1
		);
		uint256 currentPeriodAverageReward = getCurrentPeriodAverageReward(
			stakingInfo,
			totalRewardInCurrentPeriod,
			true
		);

		// 1. we update the stakingInfo.historyAverageReward with the WEIGHTED average of history reward and current reward
		stakingInfo.historyAverageReward = getNewHistoryAverageReward(
			getCurrentPeriodLength(stakingInfo, true),
			currentPeriodAverageReward,
			getHistoryLength(stakingInfo),
			stakingInfo.historyStartBlock,
			stakingInfo.historyAverageReward
		);

		// 2. we push the currentPeriodReward in the history
		stakingInfo.historyRewardPot = historyRewardPot(
				stakingInfo.historyRewardPot,
				totalRewardInCurrentPeriod,
				0
			);

		// 3. we update the stakingInfo.historyEndBlock;
		stakingInfo.historyEndBlock = uint256(block.number) - 1;
	}

	function setTicketsMintingRatio(
		StakingInfo storage stakingInfo,
		uint256 mintingRatio
	)
		public
	{
		stakingInfo.ticketsMintingRatio = mintingRatio;
	}

  // *****************************
	// *** UserStakesLib section ***
	// *****************************

	struct UserStakedToken {
		address tokenAddress;
		uint256 tokenId;
	}

	struct UserStake {
		uint256 stakingUnits;
		uint256 amountStaked;
		uint256 enteredAtBlock;
		uint256 historyAverageRewardWhenEntered;
		uint256 ticketsMintingRatioWhenEntered;
		uint256 ticketsMintingChillPeriodWhenEntered;
		uint256 lockedTill;
		uint256 rewardCredit;
		uint256 ticketsMinted;
		UserStakedToken userStakedToken;
	}

	function getTotalStakedFor(
		UserStake[] storage userStakes
	)
		public
		view
		returns (uint256)
	{
		uint256 total;

		for (uint i = 0; i < userStakes.length; i++) {
			total = total + userStakes[i].amountStaked;
		}

		return total;
	}

		/**
	* @notice Calculate the staker time in history
	* @return (uint256) number of blocks in history
	*/
	function getStakerTimeInHistory(
		StakingInfo storage stakingInfo,
		UserStake[] storage userStakes,
		uint256 stakeIndex
	)
		public
		view
		returns(uint256)
	{
		if (stakeIndex >= userStakes.length || userStakes[stakeIndex].enteredAtBlock == 0 || userStakes[stakeIndex].enteredAtBlock > stakingInfo.historyEndBlock) {
			return 0;
		}

		return stakingInfo.historyEndBlock - userStakes[stakeIndex].enteredAtBlock + 1;
	}

	/**
	* @notice Will calculate and return what the history length was a the moment the stake was created
	* @param stakeIndex the index of the stake
	* @return (uint256) The length of the history
	*/
	function getHistoryLengthBeforeStakerEntered(
		StakingInfo storage stakingInfo,
		UserStake[] storage userStakes,
		uint256 stakeIndex
	)
		public
		view
		returns (uint256)
	{
		uint256 enteredAtBlock = userStakes[stakeIndex].enteredAtBlock;

		if (enteredAtBlock == 0) {
			return 0;
		}

		return enteredAtBlock - stakingInfo.historyStartBlock - 1;
	}

	/**
	* @notice Calculate the user share in the pool
	* @param totalStakingUnits sum of all user stake shares
	* @return (uint256) the calculated pool share
	*/
	function userPoolShare(
		UserStake[] storage userStakes,
		uint256 stakeIndex,
		uint256 totalStakingUnits
	)
		public
		view
		returns(uint256)
	{
		if (stakeIndex >= userStakes.length || userStakes[stakeIndex].stakingUnits == 0) {
			return 0;
		}

		uint256 stakerBalance = userStakes[stakeIndex].stakingUnits;

		return stakerBalance * (10**18) / totalStakingUnits;
	}

	/**
	* @notice Calculate the history average for staker
	* @return (uint256) the calculated average
	*/
	function getHistoryAverageForStaker(
		StakingInfo storage stakingInfo,
		UserStake[] storage userStakes,
		uint256 stakeIndex
	)
		public
		view
		returns(uint256)
	{
		if (stakeIndex >= userStakes.length) {
			return 0;
		}

		uint256 historyAverageRewardWhenEntered = userStakes[stakeIndex].historyAverageRewardWhenEntered;
		uint256 blocksParticipatedInHistory = getStakerTimeInHistory(
			stakingInfo,
			userStakes,
			stakeIndex
		);

		if(blocksParticipatedInHistory == 0) {
			return 0;
		}
		uint256 historyLength = getHistoryLength(stakingInfo);

		uint256 historyLengthBeforeStakerEntered = getHistoryLengthBeforeStakerEntered(
			stakingInfo,
			userStakes,
			stakeIndex
		);

		return (stakingInfo.historyAverageReward * historyLength - historyAverageRewardWhenEntered * historyLengthBeforeStakerEntered) / blocksParticipatedInHistory;

	}

	/**
	* @notice Calculate the stake reward from history
	* @return (uint256) the calculated reward
	*/
	function getStakerRewardFromHistory(
		StakingInfo storage stakingInfo,
		UserStake[] storage userStakes,
		uint256 stakeIndex
	)
		public
		view
		returns(uint256)
	{
		if (stakeIndex >= userStakes.length) {
			return 0;
		}

		uint256 stakingUnits = userStakes[stakeIndex].stakingUnits;
		if (stakingUnits == 0) {
			return 0;
		}
		uint256 historyAverageForStaker = getHistoryAverageForStaker(
			stakingInfo,
			userStakes,
			stakeIndex
		);
		uint256 blocksParticipatedInHistory = getStakerTimeInHistory(
			stakingInfo,
			userStakes,
			stakeIndex
		);

		return blocksParticipatedInHistory
			* historyAverageForStaker
			* stakingUnits
			/ (10 ** 18);
	}

	/**
	* @notice Allows user to stake an nft to an existing stake for extra reward
	* @dev The NFT should be in the rarityRegister
	* @dev For each stake you can have only one NFT staked
	*/
	function _addNftToStakeAndApplyMultiplier(
		address rarityRegister,
		UserStake storage userStake,
		address tokenAddress,
		uint256 tokenId
	)
		private
	{
		uint256 rewardMultiplier = INFTRarityRegister(rarityRegister).getNftRarity(tokenAddress, tokenId);

		require(rewardMultiplier > 0, 'Staking: NFT not found in RarityRegister');
		require(rewardMultiplier >= 100, 'Staking: NFT multiplier must be at least 100');
		require(
			userStake.userStakedToken.tokenAddress == address(0),
			'Staking: Stake already has a token'
		);
		require(
			userStake.lockedTill > block.number,
			'Staking: cannot add NFT to unlocked stakes'
		);


		uint userStakingUnits = userStake.stakingUnits;

		bool success = TokenHelper.transferFrom(tokenAddress, tokenId, msg.sender, address(this));

		require(success, "Staking: could not add NFT to stake");

		userStake.userStakedToken.tokenAddress = tokenAddress;
		userStake.userStakedToken.tokenId = tokenId;

		userStake.stakingUnits = applyPercent(userStakingUnits, rewardMultiplier);
	}

	/**
	* @notice Allows user to stake an nft to an existing stake for extra reward
	* @dev The stake should exist
	* @dev when adding the NFT we need to simulate an unstake/stake because we need to recalculate the
	* new historyAverageAmount, stakingInfo.totalStakingUnits and stakingInfo.historyRewardPot
	* @notice it MUST revert if the added token has no multiplier
	*/
	function addNftToStake(
		RewardStreamerLib.RewardStreamInfo storage rewardStreamInfo,
		StakingInfo storage stakingInfo,
		UserStake[] storage userStakes,
		uint256 stakeIndex,
		address tokenAddress,
		uint256 tokenId
	)
		public
	{
		uint256 previousStakingUnits = userStakes[stakeIndex].stakingUnits; // this stays the same
		require(previousStakingUnits > 0, "Staking: Stake not found");

		uint256 stakerReward = _getStakerReward(
			rewardStreamInfo,
			stakingInfo,
			userStakes,
			stakeIndex
		);


		_addNftToStakeAndApplyMultiplier(
			stakingInfo.rarityRegister,
			userStakes[stakeIndex],
			tokenAddress,
			tokenId
		);


		uint256 newStakingUnits = userStakes[stakeIndex].stakingUnits; // after we just update it

		updateHistoryValues(rewardStreamInfo, stakingInfo);

		// we bring the stake to the current time
		userStakes[stakeIndex].enteredAtBlock = block.number;
		userStakes[stakeIndex].historyAverageRewardWhenEntered = stakingInfo.historyAverageReward;
		userStakes[stakeIndex].rewardCredit = stakerReward;

		stakingInfo.totalStakingUnits = stakingInfo.totalStakingUnits
			- previousStakingUnits
			+ newStakingUnits;

		stakingInfo.historyRewardPot = stakingInfo.historyRewardPot - stakerReward;
	}

	function _resetStake(UserStake storage userStake) private {
		userStake.stakingUnits = 0;
		userStake.rewardCredit = 0;
		userStake.amountStaked = 0;
		userStake.enteredAtBlock = 0;
		userStake.lockedTill = 0;
		userStake.ticketsMintingRatioWhenEntered = 0;
		userStake.historyAverageRewardWhenEntered = 0;
		userStake.ticketsMintingChillPeriodWhenEntered = 0;
	}


	/**
	* @notice Remove the previously staked NFT from the stake
	* @param staker the address of the owner of the stake
	*/
	function removeNftFromStake(
		UserStakedToken storage userStakedToken,
		address staker
	)
		public
	{
		if (userStakedToken.tokenAddress != address(0)) {
			uint256 tokenId = userStakedToken.tokenId;
			address tokenAddress = userStakedToken.tokenAddress;

			bool success = TokenHelper.transferFrom(tokenAddress, tokenId, address(this), staker);

			if(success) {
				delete userStakedToken.tokenId;
				delete userStakedToken.tokenAddress;
			}
		}
	}

		/**
	* @notice Allows user to unstake the staked tokens
	* @notice The tokens are allowed to be unstaked only after the lock duration has passed
	* @notice MUST trigger Unstaked event
	* @dev Unstaking tokens is an atomic operation—either all of the tokens in a stake, or none of the tokens.
	* @dev Users can only unstake a single stake at a time, it is must be their oldest active stake. Upon releasing that stake, the tokens will be
	*   transferred back to their account, and their personalStakeIndex will increment to the next active stake.
	* @return uint256 The number of tokens unstaked
	*/
	function unstake(
		RewardStreamerLib.RewardStreamInfo storage rewardStreamInfo,
		StakingInfo storage stakingInfo,
		UserStake[] storage userStakes,
		uint256 stakeIndex
	)
		public
		returns (uint256)
	{
		require(stakeIndex < userStakes.length, 'Staking: Nothing to unstake');

		require(userStakes[stakeIndex].lockedTill < block.number, "Staking: Stake is still locked");
		require(userStakes[stakeIndex].amountStaked != 0, 'Staking: Nothing to unstake');

		uint256 stakerReward = _getStakerReward(
			rewardStreamInfo,
			stakingInfo,
			userStakes,
			stakeIndex
		);


		// if for any reason the transfer fails, it will fail silently
		// and token can be withdrawn when error disappears
		removeNftFromStake(userStakes[stakeIndex].userStakedToken, msg.sender);


		uint256 totalAmount = stakerReward
			+ userStakes[stakeIndex].amountStaked
			+ userStakes[stakeIndex].rewardCredit;

		TokenHelper.ERC20Transfer(rewardStreamInfo.rewardToken, address(msg.sender), totalAmount);

		updateHistoryValues(rewardStreamInfo, stakingInfo);

		stakingInfo.totalDistributedRewards = stakingInfo.totalDistributedRewards + stakerReward + userStakes[stakeIndex].rewardCredit;
		stakingInfo.totalCurrentlyStaked = stakingInfo.totalCurrentlyStaked - userStakes[stakeIndex].amountStaked;
		stakingInfo.totalStakingUnits = stakingInfo.totalStakingUnits - userStakes[stakeIndex].stakingUnits;

		claimTickets(stakingInfo.ticket, userStakes[stakeIndex], msg.sender);
		_resetStake(userStakes[stakeIndex]);

		stakingInfo.historyRewardPot = stakingInfo.historyRewardPot - stakerReward;

		return stakerReward;
	}

	function getClaimableTickets(
		UserStake storage userStake
	)
		public
	  view
		returns (uint256)
	{
		uint256 stakingUnits = userStake.stakingUnits;
		uint256 ticketsMintingChillPeriod = userStake.ticketsMintingChillPeriodWhenEntered;
		uint256 ticketsMintingRatio = userStake.ticketsMintingRatioWhenEntered;
		uint256 ticketsMinted = userStake.ticketsMinted;

		if(stakingUnits == 0 || ticketsMintingRatio == 0 || ticketsMintingChillPeriod == 0) {
			return 0;
		}
		// 2. get chilling period length
		// 3. check how many periods have passed
		uint256 enteredAtBlock = userStake.enteredAtBlock;
		uint256 lockedTill = userStake.lockedTill;
		// 4. prevent minting more tickets after stake is unlocked

		uint256 blocksDelta = Math.min(
			(uint256(block.number) - enteredAtBlock),
			(lockedTill - enteredAtBlock)
		) + ticketsMintingChillPeriod; // count as passed from day 0
		uint256 periodsPassed = blocksDelta / ticketsMintingChillPeriod;
		// 4. multiply tickets
		uint256 multipliedUnits = stakingUnits * periodsPassed;
		// 5. get printable tickets
		uint256 printableTickets = multipliedUnits / ticketsMintingRatio;
		// 6. subtract any previously minted
		uint256 netPrintableTickets = printableTickets - ticketsMinted;
		// 5. don't print more tickets after stake is unlocked
		return netPrintableTickets;
 	}

	/**
	* @notice Mint tickets to the staker
	* @notice The amount of tickets depends on the amount of tokens staked and the duration the tokens a locked for.
	* @param ticket the address of the ticket instance
	* @param userStake the stake to claim tickets from
	* @param staker the address fo the staker
	*/
	function claimTickets(
		address ticket,
		UserStake storage userStake,
		address staker
	)
		public
	{
		uint256 netPrintableTickets = getClaimableTickets(userStake);

		if(netPrintableTickets > 0) {
			 
			TokenHelper._mintTickets(ticket, staker, netPrintableTickets);
			userStake.ticketsMinted = userStake.ticketsMinted + netPrintableTickets;
		}
 	}
}