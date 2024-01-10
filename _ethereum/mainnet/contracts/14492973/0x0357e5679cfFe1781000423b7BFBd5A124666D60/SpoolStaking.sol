// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./ReentrancyGuardUpgradeable.sol";
import "./SpoolOwnable.sol";
import "./ISpoolStaking.sol";

import "./SafeERC20.sol";
import "./SafeCast.sol";
import "./IVoSpoolRewards.sol";
import "./IVoSPOOL.sol";
import "./IRewardDistributor.sol";

/* ========== STRUCTS ========== */

// The reward configuration struct, containing all the necessary data of a typical Synthetix StakingReward contract
struct RewardConfiguration {
	uint32 rewardsDuration;
	uint32 periodFinish;
	uint192 rewardRate; // rewards per second multiplied by accuracy
	uint32 lastUpdateTime;
	uint224 rewardPerTokenStored;
	mapping(address => uint256) userRewardPerTokenPaid;
	mapping(address => uint256) rewards;
}

/**
 * @notice Implementation of the {ISpoolStaking} interface.
 *
 * @dev
 * An adaptation of the Synthetix StakingRewards contract to support multiple tokens:
 *
 * https://github.com/Synthetixio/synthetix/blob/develop/contracts/StakingRewards.sol
 *
 * At stake, gradual voSPOOL (Spool DAO Voting Token) is minted and accumulated every week.
 * At unstake all voSPOOL is burned. The maturing process of voSPOOL restarts.
 */
contract SpoolStaking is ReentrancyGuardUpgradeable, SpoolOwnable, ISpoolStaking {
	using SafeERC20 for IERC20;

	/* ========== CONSTANTS ========== */

	/// @notice Multiplier used when dealing reward calculations
	uint256 private constant REWARD_ACCURACY = 1e18;

	/* ========== STATE VARIABLES ========== */

	/// @notice SPOOL token address
	IERC20 public immutable stakingToken;

	/// @notice voSPOOL token address
	IVoSPOOL public immutable voSpool;

	/// @notice voSPOOL token rewards address
	IVoSpoolRewards public immutable voSpoolRewards;

	/// @notice Spool reward distributor
	IRewardDistributor public immutable rewardDistributor;

	/// @notice Reward token configurations
	mapping(IERC20 => RewardConfiguration) public rewardConfiguration;

	/// @notice Reward tokens
	IERC20[] public rewardTokens;

	/// @notice Blacklisted force-removed tokens
	mapping(IERC20 => bool) public tokenBlacklist;

	/// @notice Total SPOOL staked
	uint256 public totalStaked;

	/// @notice Account SPOOL staked balance
	mapping(address => uint256) public balances;

	/// @notice Whitelist showing if address can stake for another address
	mapping(address => bool) public canStakeFor;

	/// @notice Mapping showing if and what address staked for another address
	/// @dev if address is 0, noone staked for address (or unstaking was permitted)
	mapping(address => address) public stakedBy;

	/* ========== CONSTRUCTOR ========== */

	/**
	 * @notice Sets the immutable values
	 *
	 * @param _stakingToken SPOOL token
	 * @param _voSpool Spool voting token (voSPOOL)
	 * @param _voSpoolRewards voSPOOL rewards contract
	 * @param _rewardDistributor reward distributor contract
	 * @param _spoolOwner Spool DAO owner contract
	 */
	constructor(
		IERC20 _stakingToken,
		IVoSPOOL _voSpool,
		IVoSpoolRewards _voSpoolRewards,
		IRewardDistributor _rewardDistributor,
		ISpoolOwner _spoolOwner
	) SpoolOwnable(_spoolOwner) {
		stakingToken = _stakingToken;
		voSpool = _voSpool;
		voSpoolRewards = _voSpoolRewards;
		rewardDistributor = _rewardDistributor;
	}

	/* ========== INITIALIZER ========== */

	function initialize() external initializer {
		__ReentrancyGuard_init();
	}

	/* ========== VIEWS ========== */

	function lastTimeRewardApplicable(IERC20 token) public view returns (uint32) {
		return uint32(_min(block.timestamp, rewardConfiguration[token].periodFinish));
	}

	function rewardPerToken(IERC20 token) public view returns (uint224) {
		RewardConfiguration storage config = rewardConfiguration[token];

		if (totalStaked == 0) return config.rewardPerTokenStored;

		uint256 timeDelta = lastTimeRewardApplicable(token) - config.lastUpdateTime;

		if (timeDelta == 0) return config.rewardPerTokenStored;

		return SafeCast.toUint224(config.rewardPerTokenStored + ((timeDelta * config.rewardRate) / totalStaked));
	}

	function earned(IERC20 token, address account) public view returns (uint256) {
		RewardConfiguration storage config = rewardConfiguration[token];

		uint256 accountStaked = balances[account];

		if (accountStaked == 0) return config.rewards[account];

		uint256 userRewardPerTokenPaid = config.userRewardPerTokenPaid[account];

		return
			((accountStaked * (rewardPerToken(token) - userRewardPerTokenPaid)) / REWARD_ACCURACY) +
			config.rewards[account];
	}

	function rewardTokensCount() external view returns (uint256) {
		return rewardTokens.length;
	}

	/* ========== MUTATIVE FUNCTIONS ========== */

	function stake(uint256 amount) external nonReentrant updateRewards(msg.sender) {
		_stake(msg.sender, amount);

		stakingToken.safeTransferFrom(msg.sender, address(this), amount);

		emit Staked(msg.sender, amount);
	}

	function _stake(address account, uint256 amount) private {
		require(amount > 0, "SpoolStaking::_stake: Cannot stake 0");

		unchecked {
			totalStaked = totalStaked += amount;
			balances[account] += amount;
		}

		// mint gradual voSPOOL for the account
		voSpool.mintGradual(account, amount);
	}

	function compound(bool doCompoundVoSpoolRewards) external nonReentrant {
		// collect SPOOL earned fom spool rewards and stake them
		uint256 reward = _getRewardForCompound(msg.sender, doCompoundVoSpoolRewards);

		if (reward > 0) {
			// update user rewards before staking
			_updateSpoolRewards(msg.sender);

			// update user voSPOOL based reward before staking
			// skip updating voSPOOL reward if we compounded form it as it's already updated
			if (!doCompoundVoSpoolRewards) {
				_updateVoSpoolReward(msg.sender);
			}

			// stake collected reward
			_stake(msg.sender, reward);
			// move compounded SPOOL reward to this contract
			rewardDistributor.payReward(address(this), stakingToken, reward);
		}
	}

	function unstake(uint256 amount) public nonReentrant notStakedBy updateRewards(msg.sender) {
		require(amount > 0, "SpoolStaking::unstake: Cannot withdraw 0");
		require(amount <= balances[msg.sender], "SpoolStaking::unstake: Cannot unstake more than staked");

		unchecked {
			totalStaked = totalStaked -= amount;
			balances[msg.sender] -= amount;
		}

		stakingToken.safeTransfer(msg.sender, amount);

		// burn gradual voSPOOL for the sender
		if (balances[msg.sender] == 0) {
			voSpool.burnGradual(msg.sender, 0, true);
		} else {
			voSpool.burnGradual(msg.sender, amount, false);
		}

		emit Unstaked(msg.sender, amount);
	}

	function _getRewardForCompound(address account, bool doCompoundVoSpoolRewards)
		internal
		updateReward(stakingToken, account)
		returns (uint256 reward)
	{
		RewardConfiguration storage config = rewardConfiguration[stakingToken];

		reward = config.rewards[account];
		if (reward > 0) {
			config.rewards[account] = 0;
			emit RewardCompounded(msg.sender, reward);
		}

		if (doCompoundVoSpoolRewards) {
			_updateVoSpoolReward(account);
			uint256 voSpoolreward = voSpoolRewards.flushRewards(account);

			if (voSpoolreward > 0) {
				reward += voSpoolreward;
				emit VoRewardCompounded(msg.sender, reward);
			}
		}
	}

	function getRewards(IERC20[] memory tokens, bool doClaimVoSpoolRewards) external nonReentrant notStakedBy {
		for (uint256 i; i < tokens.length; i++) {
			_getReward(tokens[i], msg.sender);
		}

		if (doClaimVoSpoolRewards) {
			_getVoSpoolRewards(msg.sender);
		}
	}

	function getActiveRewards(bool doClaimVoSpoolRewards) external nonReentrant notStakedBy {
		_getActiveRewards(msg.sender);

		if (doClaimVoSpoolRewards) {
			_getVoSpoolRewards(msg.sender);
		}
	}

	function getUpdatedVoSpoolRewardAmount() external returns (uint256 rewards) {
		// update rewards
		rewards = voSpoolRewards.updateRewards(msg.sender);
		// update and store users voSPOOL
		voSpool.updateUserVotingPower(msg.sender);
	}

	function _getActiveRewards(address account) internal {
		uint256 _rewardTokensCount = rewardTokens.length;
		for (uint256 i; i < _rewardTokensCount; i++) {
			_getReward(rewardTokens[i], account);
		}
	}

	function _getReward(IERC20 token, address account) internal updateReward(token, account) {
		RewardConfiguration storage config = rewardConfiguration[token];

		require(config.rewardsDuration != 0, "SpoolStaking::_getReward: Bad reward token");

		uint256 reward = config.rewards[account];
		if (reward > 0) {
			config.rewards[account] = 0;
			rewardDistributor.payReward(account, token, reward);
			emit RewardPaid(token, account, reward);
		}
	}

	function _getVoSpoolRewards(address account) internal {
		_updateVoSpoolReward(account);
		uint256 reward = voSpoolRewards.flushRewards(account);

		if (reward > 0) {
			rewardDistributor.payReward(account, stakingToken, reward);
			emit VoSpoolRewardPaid(stakingToken, account, reward);
		}
	}

	/* ========== RESTRICTED FUNCTIONS ========== */

	function stakeFor(address account, uint256 amount)
		external
		nonReentrant
		canStakeForAddress(account)
		updateRewards(account)
	{
		_stake(account, amount);
		stakingToken.safeTransferFrom(msg.sender, address(this), amount);
		stakedBy[account] = msg.sender;

		emit StakedFor(account, msg.sender, amount);
	}

	/**
	 * @notice Allow unstake for `allowFor` address
	 * @dev
	 *
	 * Requirements:
	 *
	 * - the caller must be the Spool DAO or address that staked for `allowFor` address
	 *
	 * @param allowFor address to allow unstaking for
	 */
	function allowUnstakeFor(address allowFor) external {
		require(
			(canStakeFor[msg.sender] && stakedBy[allowFor] == msg.sender) || isSpoolOwner(),
			"SpoolStaking::allowUnstakeFor: Cannot allow unstaking for address"
		);
		// reset address to 0 to allow unstaking
		stakedBy[allowFor] = address(0);
	}

	/**
	 * @notice Allows a new token to be added to the reward system
	 *
	 * @dev
	 * Emits an {TokenAdded} event indicating the newly added reward token
	 * and configuration
	 *
	 * Requirements:
	 *
	 * - the caller must be the reward Spool DAO
	 * - the reward duration must be non-zero
	 * - the token must not have already been added
	 *
	 */
	function addToken(
		IERC20 token,
		uint32 rewardsDuration,
		uint256 reward
	) external onlyOwner {
		RewardConfiguration storage config = rewardConfiguration[token];

		require(!tokenBlacklist[token], "SpoolStaking::addToken: Cannot add blacklisted token");
		require(rewardsDuration != 0, "SpoolStaking::addToken: Reward duration cannot be 0");
		require(config.lastUpdateTime == 0, "SpoolStaking::addToken: Token already added");

		rewardTokens.push(token);

		config.rewardsDuration = rewardsDuration;

		if (reward > 0) {
			_notifyRewardAmount(token, reward);
		}
	}

	function notifyRewardAmount(
		IERC20 token,
		uint32 _rewardsDuration,
		uint256 reward
	) external onlyOwner {
		RewardConfiguration storage config = rewardConfiguration[token];
		config.rewardsDuration = _rewardsDuration;
		require(
			rewardConfiguration[token].lastUpdateTime != 0,
			"SpoolStaking::notifyRewardAmount: Token not yet added"
		);
		_notifyRewardAmount(token, reward);
	}

	function _notifyRewardAmount(IERC20 token, uint256 reward) private updateReward(token, address(0)) {
		RewardConfiguration storage config = rewardConfiguration[token];

		require(
			config.rewardPerTokenStored + (reward * REWARD_ACCURACY) <= type(uint192).max,
			"SpoolStaking::_notifyRewardAmount: Reward amount too big"
		);

		uint32 newPeriodFinish = uint32(block.timestamp) + config.rewardsDuration;

		if (block.timestamp >= config.periodFinish) {
			config.rewardRate = SafeCast.toUint192((reward * REWARD_ACCURACY) / config.rewardsDuration);
			emit RewardAdded(token, reward, config.rewardsDuration);
		} else {
			uint256 remaining = config.periodFinish - block.timestamp;
			uint256 leftover = remaining * config.rewardRate;
			uint192 newRewardRate = SafeCast.toUint192((reward * REWARD_ACCURACY + leftover) / config.rewardsDuration);

			config.rewardRate = newRewardRate;
			emit RewardUpdated(token, reward, leftover, config.rewardsDuration, newPeriodFinish);
		}

		config.lastUpdateTime = uint32(block.timestamp);
		config.periodFinish = newPeriodFinish;
	}

	// End rewards emission earlier
	function updatePeriodFinish(IERC20 token, uint32 timestamp) external onlyOwner updateReward(token, address(0)) {
		if (rewardConfiguration[token].lastUpdateTime > timestamp) {
			rewardConfiguration[token].periodFinish = rewardConfiguration[token].lastUpdateTime;
		} else {
			rewardConfiguration[token].periodFinish = timestamp;
		}

		emit PeriodFinishUpdated(token, rewardConfiguration[token].periodFinish);
	}

	/**
	 * @notice Remove reward from vault rewards configuration.
	 * @dev
	 * Used to sanitize vault and save on gas, after the reward has ended.
	 * Users will be able to claim rewards
	 *
	 * Requirements:
	 *
	 * - the caller must be the spool owner or Spool DAO
	 * - cannot claim vault underlying token
	 * - cannot only execute if the reward finished
	 *
	 * @param token Token address to remove
	 */
	function removeReward(IERC20 token) external onlyOwner onlyFinished(token) updateReward(token, address(0)) {
		_removeReward(token);
	}

	/**
	 * @notice Allow an address to stake for another address.
	 * @dev
	 * Requirements:
	 *
	 * - the caller must be the distributor
	 *
	 * @param account Address to allow
	 * @param _canStakeFor True to allow, false to remove allowance
	 */
	function setCanStakeFor(address account, bool _canStakeFor) external onlyOwner {
		canStakeFor[account] = _canStakeFor;
		emit CanStakeForSet(account, _canStakeFor);
	}

	function recoverERC20(
		IERC20 tokenAddress,
		uint256 tokenAmount,
		address recoverTo
	) external onlyOwner {
		require(tokenAddress != stakingToken, "SpoolStaking::recoverERC20: Cannot withdraw the staking token");
		tokenAddress.safeTransfer(recoverTo, tokenAmount);
	}

	/* ========== PRIVATE FUNCTIONS ========== */

	/**
	 * @notice Syncs rewards across all tokens of the system
	 *
	 * This function is meant to be invoked every time the instant deposit
	 * of a user changes.
	 */
	function _updateRewards(address account) private {
		// update SPOOL based rewards
		_updateSpoolRewards(account);

		// update voSPOOL based reward
		_updateVoSpoolReward(account);
	}

	function _updateSpoolRewards(address account) private {
		uint256 _rewardTokensCount = rewardTokens.length;

		// update SPOOL based rewards
		for (uint256 i; i < _rewardTokensCount; i++) _updateReward(rewardTokens[i], account);
	}

	function _updateReward(IERC20 token, address account) private {
		RewardConfiguration storage config = rewardConfiguration[token];
		config.rewardPerTokenStored = rewardPerToken(token);
		config.lastUpdateTime = lastTimeRewardApplicable(token);
		if (account != address(0)) {
			config.rewards[account] = earned(token, account);
			config.userRewardPerTokenPaid[account] = config.rewardPerTokenStored;
		}
	}

	/**
	 * @notice Update rewards collected from account voSPOOL
	 * @dev
	 * First we update rewards calling `voSpoolRewards.updateRewards`
	 * - Here we only simulate the reward accumulated over tranches
	 * Then we update and store users power by calling voSPOOL contract
	 * - Here we actually store the udated values.
	 * - If store wouldn't happen, next time we'd simulate the same voSPOOL tranches again
	 */
	function _updateVoSpoolReward(address account) private {
		// update rewards
		voSpoolRewards.updateRewards(account);
		// update and store users voSPOOL
		voSpool.updateUserVotingPower(account);
	}

	function _removeReward(IERC20 token) private {
		uint256 _rewardTokensCount = rewardTokens.length;
		for (uint256 i; i < _rewardTokensCount; i++) {
			if (rewardTokens[i] == token) {
				rewardTokens[i] = rewardTokens[_rewardTokensCount - 1];

				rewardTokens.pop();
				emit RewardRemoved(token);
				break;
			}
		}
	}

	function _onlyFinished(IERC20 token) private view {
		require(
			block.timestamp > rewardConfiguration[token].periodFinish,
			"SpoolStaking::_onlyFinished: Reward not finished"
		);
	}

	function _min(uint256 a, uint256 b) private pure returns (uint256) {
		return a > b ? b : a;
	}

	/* ========== MODIFIERS ========== */

	modifier updateReward(IERC20 token, address account) {
		_updateReward(token, account);
		_;
	}

	modifier updateRewards(address account) {
		_updateRewards(account);
		_;
	}

	modifier canStakeForAddress(address account) {
		// verify sender can stake for
		require(
			canStakeFor[msg.sender] || isSpoolOwner(),
			"SpoolStaking::canStakeForAddress: Cannot stake for other addresses"
		);

		// if address already staked, verify further
		if (balances[account] > 0) {
			// verify address was staked by some other address
			require(stakedBy[account] != address(0), "SpoolStaking::canStakeForAddress: Address already staked");

			// verify address was staked by the sender or sender is the Spool DAO
			require(
				stakedBy[account] == msg.sender || isSpoolOwner(),
				"SpoolStaking::canStakeForAddress: Address staked by another address"
			);
		}
		_;
	}

	modifier notStakedBy() {
		require(stakedBy[msg.sender] == address(0), "SpoolStaking::notStakedBy: Cannot withdraw until allowed");
		_;
	}

	modifier onlyFinished(IERC20 token) {
		_onlyFinished(token);
		_;
	}
}
