// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./MathUpgradeable.sol";
import "./SafeMathUpgradeable.sol";

import "./AletheaStakingSpec.sol";

// Inheritance
contract AletheaStakingImpl is AletheaStaking, UUPSUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable, PausableUpgradeable {
	using SafeMathUpgradeable for uint256;
	using SafeERC20Upgradeable for IERC20Upgradeable;

	/* ========== STATE VARIABLES ========== */

	uint256 public periodFinish;
	uint256 public rewardRate;
	uint256 public rewardsDuration;
	uint256 public lastUpdateTime;
	uint256 public rewardPerTokenStored;
	uint256 public lastBalance;
	uint256 public totalSupply;

	// IERC20 public rewardsToken;
	// IERC20 public stakingToken;
	IERC20Upgradeable public token;

	mapping(address => uint256) private userRewardPerTokenPaid;
	mapping(address => uint256) private rewards;
	mapping(address => uint256) private _balances;

	/* ========== EVENTS ========== */

	event RewardAdded(uint256 reward);
	event Staked(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RewardPaid(address indexed user, uint256 reward);
	event Recovered(address token, uint256 amount);
	event RewardRateUpdated(uint256 rewardsPerInterval, uint256 interval, uint256 rewardRate);

	/* ========== MODIFIERS ========== */

	modifier updateReward(address account) {
		rewardPerTokenStored = rewardPerToken();
		lastUpdateTime = lastTimeRewardApplicable();
		if (account != address(0)) {
			rewards[account] = earned(account);
			userRewardPerTokenPaid[account] = rewardPerTokenStored;
		}
		_;
	}

	/* ========== CONSTRUCTOR ========== */

	function postConstruct(IERC20Upgradeable _token) public virtual initializer {
		require(address(_token) != address(0x0));

		token = _token;

		__Ownable_init();
		__Pausable_init_unchained();
		__ReentrancyGuard_init();
	}

	/* ========== VIEWS ========== */

	function balanceOf(address account) external override view returns (uint256) {
		return _balances[account];
	}

	function lastTimeRewardApplicable() public override view returns (uint256) {
		return MathUpgradeable.min(now256(), periodFinish);
	}

	function rewardPerToken() public override view returns (uint256) {
		if (totalSupply == 0) {
			return rewardPerTokenStored;
		}
		return rewardPerTokenStored.add(lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(totalSupply));
	}

	function earned(address account) public override view returns (uint256) {
		return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
	}

	/* ========== MUTATIVE FUNCTIONS ========== */

	function stake(uint256 amount) external override nonReentrant whenNotPaused updateReward(msg.sender) {
		require(amount > 0, 'Cannot stake 0');
		totalSupply = totalSupply.add(amount);
		_balances[msg.sender] = _balances[msg.sender].add(amount);
		token.safeTransferFrom(msg.sender, address(this), amount);
		emit Staked(msg.sender, amount);
	}

	function withdraw(uint256 amount) public override nonReentrant updateReward(msg.sender) {
		require(amount > 0, 'Cannot withdraw 0');
		totalSupply = totalSupply.sub(amount);
		_balances[msg.sender] = _balances[msg.sender].sub(amount);
		token.safeTransfer(msg.sender, amount);
		emit Withdrawn(msg.sender, amount);
	}

	function getReward() public override nonReentrant updateReward(msg.sender) {
		uint256 reward = rewards[msg.sender];
		if (reward > 0) {
			rewards[msg.sender] = 0;
			token.safeTransfer(msg.sender, reward);
			emit RewardPaid(msg.sender, reward);
		}
	}

	function exit() external override {
		withdraw(_balances[msg.sender]);
		getReward();
	}

	/* ========== RESTRICTED FUNCTIONS ========== */

	function notifyRewardAmount(uint256 reward) external onlyOwner updateReward(address(0)) {
		require(rewardRate > 0, 'Reward Rate is not yet set');
		if (now256() >= periodFinish) {
			rewardsDuration = reward.div(rewardRate);
		} else {
			uint256 remaining = periodFinish.sub(now256());
			uint256 leftover = remaining.mul(rewardRate);
			rewardsDuration = reward.add(leftover).div(rewardRate);
		}

		// Ensure the provided reward amount is not more than the balance in the contract.
		// This keeps the reward rate in the right range, preventing overflows due to
		// very high values of rewardRate in the earned and rewardsPerToken functions;
		// Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
		uint256 balance = token.balanceOf(address(this)).sub(totalSupply);
		require(rewardRate <= balance.div(rewardsDuration), 'Provided reward too high');

		lastUpdateTime = now256();
		periodFinish = now256().add(rewardsDuration);
		emit RewardAdded(reward);
	}

	function setRewardRate(uint256 rewardsPerInterval, uint256 interval) external onlyOwner {
		require(rewardsPerInterval > 0 && interval > 0, 'rewardsPerInterval and interval should be greater than 0');
		require(now256() > periodFinish, 'Previous rewards period must be complete before changing the reward rate');
		rewardRate = rewardsPerInterval.div(interval);

		emit RewardRateUpdated(rewardsPerInterval, interval, rewardRate);
	}

	// Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
	function recoverERC20(IERC20Upgradeable _token, uint256 tokenAmount) external onlyOwner {
		require(address(_token) != address(token), "Cannot withdraw the staking token");
		_token.safeTransfer(owner(), tokenAmount);
		emit Recovered(address(_token), tokenAmount);
	}

	/**
	 * @inheritdoc UUPSUpgradeable
	 */
	function _authorizeUpgrade(address) internal virtual override onlyOwner {}

	/**
	 * @dev Testing time-dependent functionality may be difficult;
	 *      we override time in the helper test smart contract (mock)
	 *
	 * @return `block.timestamp` in mainnet, custom values in testnets (if overridden)
	 */
	function now256() public view virtual returns (uint256) {
		// return current block timestamp
		return block.timestamp;
	}
}
