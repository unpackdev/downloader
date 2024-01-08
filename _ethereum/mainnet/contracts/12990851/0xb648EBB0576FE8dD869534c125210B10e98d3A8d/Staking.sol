// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

import "./IERC900.sol";
import "./RewardStreamer.sol";
import "./StakingLib.sol";

/// @title A Staking smart contract
/// @author Valerio Leo @valerioHQ
contract Staking is Initializable, IERC900, OwnableUpgradeable, RewardStreamer {
	StakingLib.StakingInfo stakingInfo;

	mapping(address => StakingLib.UserStake[]) private _userStakes;

	/**
	 * Constructor
	 * @param _rewardToken The reward token address
	 * @param _ticket The raffle ticket address
	 * @param _locks The array with the locks durations values
	 * @param _rarityRegister The rarity register address
	 */
	function initialize (
		address _rewardToken,
		address _ticket,
		uint256[] memory _locks,
		uint256[] memory _locksMultiplier,
		uint256 _ticketsMintingRatio,
		uint256 _ticketsMintingChillPeriod,
		address _rarityRegister,
		address _defaultStaker
	) public initializer {
		require(_locks.length == _locksMultiplier.length, 'Stake: lock multiplier should have the same length ad locks');
		OwnableUpgradeable.__Ownable_init();

		super._setRewardToken(_rewardToken);

		// add the default staker. we need a default staker to neveer have 0 staking units
		_addStaker(_defaultStaker, 1 * 10**18, block.number + 1, 0);

		stakingInfo.totalStakingUnits = stakingInfo.totalStakingUnits + (1 * 10 ** 18);
		stakingInfo.totalCurrentlyStaked = stakingInfo.totalCurrentlyStaked + (1 * 10 ** 18);

		stakingInfo.locks = _locks;
		stakingInfo.locksMultiplier = _locksMultiplier;
		stakingInfo.historyStartBlock = block.number;
		stakingInfo.historyEndBlock = block.number;

		setTicketsMintingChillPeriod(_ticketsMintingChillPeriod);
		setTicketsMintingRatio(_ticketsMintingRatio);
		setTicket(_ticket);
		setRarityRegister(_rarityRegister);

		RewardStreamer.rewardStreamInfo.deployedAtBlock = block.number;
	}

	/**
	* @notice Will create a new reward stream
	* @param rewardStreamIndex The reward index
	* @param periodBlockRate The reward per block
	* @param periodLastBlock The last block of the period
	*/
	function addRewardStream(uint256 rewardStreamIndex, uint256 periodBlockRate, uint256 periodLastBlock) public onlyOwner {
		super._addRewardStream(rewardStreamIndex, periodBlockRate, periodLastBlock);
	}

	/**
	* @notice Will add a new lock duration value
	* @param lockNumber the new lock duration value
	*/
	function addLockDuration(uint256 lockNumber, uint256 lockMultiplier) public onlyOwner {
		stakingInfo.locks.push(lockNumber);
		stakingInfo.locksMultiplier.push(lockMultiplier);

		emit LocksUpdated(stakingInfo.locks.length - 1, lockNumber, lockMultiplier);
	}

	event LocksUpdated(uint256 lockIndex, uint256 lockNumber, uint256 lockMultiplier);
	/**
	* @notice Will update an existing lock value
	* @param lockIndex the lock index
	* @param lockNumber the new lock duration value
	*/
	function updateLocks(uint256 lockIndex, uint256 lockNumber, uint256 lockMultiplier) public onlyOwner {
		stakingInfo.locks[lockIndex] = lockNumber;
		stakingInfo.locksMultiplier[lockIndex] = lockMultiplier;

		emit LocksUpdated(lockIndex, lockNumber, lockMultiplier);
	}

	event TicketMintingChillPeriodUpdated(uint256 newValue);

	/**
	* @notice Will update the ticketsMintingChillPeriod
	* @param newTicketsMintingChillPeriod the new value
	*/
	function setTicketsMintingChillPeriod(uint256 newTicketsMintingChillPeriod) public onlyOwner {
		require(newTicketsMintingChillPeriod > 0, "Staking: ticketsMintingChillPeriod can't be zero");
		stakingInfo.ticketsMintingChillPeriod = newTicketsMintingChillPeriod;

		emit TicketMintingChillPeriodUpdated(newTicketsMintingChillPeriod);
	}

	event TicketMintingRatioUpdated(uint256 newValue);
	/**
	* @notice Will update the numebr of staking units needed to earn one ticket
	* @param newTicketsMintingRatio the new value
	*/
	function setTicketsMintingRatio(uint256 newTicketsMintingRatio) public onlyOwner {
		stakingInfo.ticketsMintingRatio = newTicketsMintingRatio;

		emit TicketMintingRatioUpdated(newTicketsMintingRatio);
	}

	/**
	* @notice Will update the ticket address
	* @param ticketAddress the new value
	*/
	function setTicket(address ticketAddress) public onlyOwner {
		stakingInfo.ticket = ticketAddress;
	}


	event RarityRegisterUpdated(address rarityRegister);
	/**
	* @notice Will update the rarityRegister address
	* @param newRarityRegister the new value
	*/
	function setRarityRegister(address newRarityRegister) public onlyOwner {
		stakingInfo.rarityRegister = newRarityRegister;

		emit RarityRegisterUpdated(newRarityRegister);
	}


	/**
	* @notice Will calculate the total reward generated from start till now
	* @return (uint256) The the calculated reward
	*/
	function getTotalGeneratedReward() external view returns(uint256) {
		return RewardStreamerLib.unsafeGetRewardsFromRange(rewardStreamInfo, stakingInfo.historyStartBlock, block.number);
	}

	function historyStartBlock() public view returns (uint256) {return stakingInfo.historyStartBlock;}
	function historyEndBlock() public view returns (uint256) {return stakingInfo.historyEndBlock;}
	function historyAverageReward() public view returns (uint256) {return stakingInfo.historyAverageReward;}
	function historyRewardPot() public view returns (uint256) {return stakingInfo.historyRewardPot;}
	function totalCurrentlyStaked() public view returns (uint256) {return stakingInfo.totalCurrentlyStaked;}
	function totalStakingUnits() public view returns (uint256) {return stakingInfo.totalStakingUnits;}
	function totalDistributedRewards() public view returns (uint256) {return stakingInfo.totalDistributedRewards;}
	function ticketsMintingRatio() public view returns (uint256) {return stakingInfo.ticketsMintingRatio;}
	function ticketsMintingChillPeriod() public view returns (uint256) {return stakingInfo.ticketsMintingChillPeriod;}
	function rarityRegister() public view returns (address) {return stakingInfo.rarityRegister;}
	function locks(uint256 i) public view returns (uint256) {return stakingInfo.locks[i];}
	function locksMultiplier(uint256 i) public view returns (uint256) {return stakingInfo.locksMultiplier[i];}
	function userStakes(address staker, uint256 i) public view returns (StakingLib.UserStake memory) {
		StakingLib.UserStake memory s;

		return _userStakes[staker].length > i
			? _userStakes[staker][i]
			: s;
	}
	function userStakedTokens(address staker, uint256 stakeIndex) public view returns (StakingLib.UserStakedToken memory) {
		StakingLib.UserStakedToken memory s;

		return _userStakes[staker].length > stakeIndex
			? _userStakes[staker][stakeIndex].userStakedToken
			: s;
	}

	/**
	* @notice Will calculate the current period length
	* @return (uint256) The current period length
	*/
	function getCurrentPeriodLength() public view returns(uint256) {
		return StakingLib.getCurrentPeriodLength(stakingInfo);
	}

	/**
	* @notice Will calculate the current period total reward
	* @return (uint256) The current period total reward
	*/
	function getTotalRewardInCurrentPeriod() public view returns(uint256) {
		return RewardStreamerLib.unsafeGetRewardsFromRange(rewardStreamInfo, stakingInfo.historyEndBlock, block.number);
	}

	/**
	* @notice Will calculate the current period average reward
	* @return (uint256) The current period average
	*/
	function getCurrentPeriodAverageReward() public view returns(uint256) {
		return StakingLib.getCurrentPeriodAverageReward(
			stakingInfo,
			getTotalRewardInCurrentPeriod(),
			false
		);
	}

	/**
	* @notice Will calculate the history length in blocks
	* @return (uint256) The history length
	*/
	function getHistoryLength() public view returns (uint256){
		return StakingLib.getHistoryLength(stakingInfo);
	}

	/**
	* @notice Will get the pool share for a specific stake
	* @param staker the address of the owner of the stake
	* @param stakeIndex the index of the stake
	* @return (uint256) The userPoolShare
	*/
	function getStakerPoolShare(address staker, uint256 stakeIndex) public view returns (uint256) {
		return StakingLib.userPoolShare(
			_userStakes[staker],
			stakeIndex,
			stakingInfo.totalStakingUnits
		);
	}


	/**
	* @notice Will get the reward of a stake for the current period
	* @param staker the address of the owner of the stake
	* @param stakeIndex the index of the stake
	* @return (uint256) The reward for current period
	*/
	function getStakerRewardFromCurrent(address staker, uint256 stakeIndex) public view returns (uint256) {
		return StakingLib.getStakerRewardFromCurrentPeriod(
			rewardStreamInfo,
			stakingInfo,
			_userStakes[staker],
			stakeIndex
		);
	}

	/**
	* @notice Will calculate and return for how many block the stake has in history
	* @param staker the address of the owner of the stake
	* @param stakeIndex the index of the stake
	* @return (uint256) The number of blocks in history
	*/
	function getStakerTimeInHistory(address staker, uint256 stakeIndex) public view returns (uint256) {
		return StakingLib.getStakerTimeInHistory(
			stakingInfo,
			_userStakes[staker],
			stakeIndex
		);
	}

	/**
	* @notice Will calculate and return what the history length was a the moment the stake was created
	* @param staker the address of the owner of the stake
	* @param stakeIndex the index of the stake
	* @return (uint256) The length of the history
	*/
	function getHistoryLengthBeforeStakerEntered(address staker, uint256 stakeIndex) public view returns (uint256) {
		return StakingLib.getHistoryLengthBeforeStakerEntered(
			stakingInfo,
			_userStakes[staker],
			stakeIndex
		);
	}

	/**
	* @notice Will calculate and return the history average for a stake
	* @param staker the address of the owner of the stake
	* @param stakeIndex the index of the stake
	* @return (uint256) The calculated history average
	*/
	function getHistoryAverageForStake(address staker, uint256 stakeIndex) public view returns (uint256) {
		return StakingLib.getHistoryAverageForStaker(
			stakingInfo,
			_userStakes[staker],
			stakeIndex
		);
	}

	/**
	* @return (uint256) The number of all the stakes user has ever staked
	*/
	function getUserStakes(address staker) public view returns(uint256) {
		return _userStakes[staker].length;
	}

	/**
	* @notice Will calculate and return the total reward user has accumulated till now for a specific stake
	* @param staker the address of the owner of the stake
	* @param stakeIndex the index of the stake
	* @return (uint256) The total rewards accumulated till now
	*/
	function getStakerReward(address staker, uint256 stakeIndex) public view returns (uint256) {
		return StakingLib.getStakerReward(
			rewardStreamInfo,
			stakingInfo,
			_userStakes[staker],
			stakeIndex
		);
	}

	/**
	* @notice Will calculate the rewards that user will get from history
	* @param staker the address of the staker you wish to get the rewards
	* @param stakeIndex the index of the stake
	* @return uint256 The amount of tokes user will get from history
	*/
	function getStakerRewardFromHistory(address staker, uint256 stakeIndex) public view returns (uint256) {
		return StakingLib.getStakerRewardFromHistory(
			stakingInfo,
			_userStakes[staker],
			stakeIndex
		);
	}

	function getClaimableTickets(address staker, uint256 stakeIndex) public view returns (uint256) {
		require(_userStakes[staker].length > stakeIndex, "Staking: stake does not exist");

		return StakingLib.getClaimableTickets(
			_userStakes[staker][stakeIndex]
		);
	}

	function claimTickets(uint256 stakeIndex) public {
		require(_userStakes[msg.sender].length > stakeIndex, "Staking: stake does not exist");

		StakingLib.claimTickets(
			stakingInfo.ticket,
			_userStakes[msg.sender][stakeIndex],
			msg.sender
		);
	}

	/**
	* @notice Creates a stake instance for the staker
	* @notice MUST trigger Staked event
	* @dev The NFT should be in the rarityRegister
	* @dev For each stake you can have only one NFT staked
	* @param stakerAddress the address of the owner of the stake
	* @param amountStaked the number of tokens to be staked
	* @param blockNumber the block number at which the stake is created
	* @param lockDuration the duration for which the tokens will be locked
	*/
	function _addStaker(address stakerAddress, uint256 amountStaked, uint256 blockNumber, uint256 lockDuration) internal {
		_userStakes[stakerAddress].push(StakingLib.UserStake({
			amountStaked: amountStaked,
			stakingUnits: amountStaked,
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

		emit Staked(stakerAddress, amountStaked, stakingInfo.totalCurrentlyStaked, abi.encodePacked(_userStakes[stakerAddress].length - 1));
	}

	/**
	* @notice Allows user to stake tokens
	* @notice Optionaly user can stake an NFT token for extra reward
	* @dev Users wil be able to unstake only after the lock durationn has pased.
	* @dev The lock duration in the data bytes is required, its the index of the locks array
	* Should be the fist 32 bytes in the bytes array
	* @param amount the inumber of tokens to be staked
	* @param data the bytes containing extra information about the staking
	* lock duration index: fist 32 bytes (Number) - Required
	* NFT address: next 20 bytes (address)
	* NFT tokenId: next 32 bytes (Number)
	*/
	function stake(uint256 amount, bytes calldata data) public override {
		StakingLib.stake(
			rewardStreamInfo,
			stakingInfo,
			_userStakes[msg.sender],
			msg.sender,
			amount,
			data
		);

		emit Staked(
			msg.sender,
			amount,
			stakingInfo.totalCurrentlyStaked,
			abi.encodePacked(_userStakes[msg.sender].length - 1)
		);
	}

	/**
	* @notice Stakes a certain amount of tokens, this MUST transfer the given amount from the caller
	* @notice MUST trigger Staked event
	* @param user the address the tokens are staked for
	* @param amount uint256 the amount of tokens to stake
	* @param data bytes aditional data for the stake and to include in the Stake event
	* lock duration index: fist 32 bytes (Number) - Required
	* NFT address: next 20 bytes (address)
	* NFT tokenId: next 32 bytes (Number)
	*/
	function stakeFor(address user, uint256 amount, bytes calldata data) external override {
		StakingLib.stake(
			rewardStreamInfo,
			stakingInfo,
			_userStakes[user],
			user,
			amount,
			data
		);
		emit Staked(user, amount, stakingInfo.totalCurrentlyStaked, abi.encodePacked(_userStakes[user].length  - 1));
	}

	/**
	* @notice Allows user to stake an nft to an existing stake for extra reward
	* @dev The stake should exist
	* @dev when adding the NFT we need to simulate an untake/stake because we need to recalculate the
	* new historyAverageAmount, stakingInfo.totalStakingUnits and stakingInfo.historyRewardPot
	* @notice it MUST revert if the added token has no multiplier
	* @param staker the address of the owner of the stake
	* @param stakeIndex the index of the stake
	* @param tokenAddress the address of the NFT
	* @param tokenId the id of the NFT token
	*/
	function addNftToStake(address staker, uint256 stakeIndex, address tokenAddress, uint256 tokenId) public {
		StakingLib.addNftToStake(
			rewardStreamInfo,
			stakingInfo,
			_userStakes[staker],
			stakeIndex,
			tokenAddress,
			tokenId
		);
	}

	/**
	* @notice Unstakes a certain amount of tokens, this SHOULD return the given amount of tokens to the user, if unstaking is currently not possible the function MUST revert
	* @notice MUST trigger Unstaked event
	* @dev Unstaking tokens is an atomic operation—either all of the tokens in a stake, or none of the tokens.
	* @dev Users can only unstake a single stake at a time, it is must be their oldest active stake. Upon releasing that stake, the tokens will be
	*   transferred back to their account, and their personalStakeIndex will increment to the next active stake.
	* @param amount uint256 the amount of tokens to unstake
	* @param data bytes optional data to include in the Unstake event
	*/
	function unstake(uint256 amount, bytes calldata data) public override {
		uint256 stakerReward = StakingLib.unstake(
			rewardStreamInfo,
			stakingInfo,
			_userStakes[msg.sender],
			StakingLib.getStakeIndexFromCalldata(data)
		);

		emit Unstaked(
			msg.sender,
			stakerReward,
			stakingInfo.totalCurrentlyStaked,
			abi.encodePacked(StakingLib.getStakeIndexFromCalldata(data))
		);
	}

	/**
	* @notice This function offers a way to withdraw a ERC721 after using failsafeUnstakeERC20.
	* @notice If for any reason the ERC721 should function again, this function allows to withdraw it.
	* @param data bytes optional data to include in the Unstake event
	*/
	function unstakeERC721(bytes calldata data) external {
		uint256 stakeIndex = StakingLib.getStakeIndexFromCalldata(data);
		require(_userStakes[msg.sender][stakeIndex].lockedTill < block.number, "Staking: Stake is still locked");

		StakingLib.removeNftFromStake(
			_userStakes[msg.sender][stakeIndex].userStakedToken,
			msg.sender
		);
	}

	/**
	* @notice Returns the current total of tokens staked for an address
	* @param staker address The address to query
	* @return uint256 The number of tokens staked for the given address
	*/
	function totalStakedFor(address staker) external override view returns (uint256) {
		return StakingLib.getTotalStakedFor(_userStakes[staker]);
	}

	/**
	* @notice Returns the current total of tokens staked
	* @return uint256 The number of tokens staked in the contract
	*/
	function totalStaked() external override view returns (uint256) {
		return stakingInfo.totalCurrentlyStaked;
	}

	/**
	* @notice MUST return true if the optional history functions are implemented, otherwise false
	* @dev Since we don't implement the optional interface, this always returns false
	* @return bool Whether or not the optional history functions are implemented
	*/
	function supportsHistory() external override pure returns (bool) {
		return false;
	}

	/**
	* @notice Address of the token being used by the staking interface
	* @return address The address of the ERC20 token used for staking
	*/
	function token() external override view returns (address) {
		return address(rewardStreamInfo.rewardToken);
	}
}
