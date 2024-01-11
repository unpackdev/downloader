// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./MathUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";

contract GaugeMultiRewards is ReentrancyGuardUpgradeable, PausableUpgradeable, ERC20Upgradeable {
	using SafeERC20Upgradeable for ERC20Upgradeable;

	/* ========== STATE VARIABLES ========== */

	struct Reward {
		address rewardsDistributor;
		uint256 rewardsDuration;
		uint256 periodFinish;
		uint256 rewardRate;
		uint256 lastUpdateTime;
		uint256 rewardPerTokenStored;
	}

	ERC20Upgradeable public stakingToken;
	address public vault;

	mapping(address => Reward) public rewardData;

	address public governance;
	address[] public rewardTokens;

	// user -> reward token -> amount
	mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;
	mapping(address => mapping(address => uint256)) public rewards;

	uint256 private _totalStake;
	uint256 public derivedSupply;

	mapping(address => uint256) private _stakes;
	mapping(address => uint256) public derivedBalances;

	/* ========== CONSTRUCTOR ========== */

	function init(
		address _stakingToken,
		address _vault,
		address _governance,
		string memory _name,
		string memory _symbol
	) public initializer {
		__ERC20_init(_name, _symbol);
		governance = _governance;
		stakingToken = ERC20Upgradeable(_stakingToken);
		vault = _vault;
	}

	function addReward(
		address _rewardsToken,
		address _rewardsDistributor,
		uint256 _rewardsDuration
	) public onlyGovernance {
		require(rewardData[_rewardsToken].rewardsDuration == 0);
		rewardTokens.push(_rewardsToken);
		rewardData[_rewardsToken].rewardsDistributor = _rewardsDistributor;
		rewardData[_rewardsToken].rewardsDuration = _rewardsDuration;
	}

	/* ========== VIEWS ========== */

	function totalStaked() external view returns (uint256) {
		return _totalStake;
	}

	function stakeOf(address account) external view returns (uint256) {
		return _stakes[account];
	}

	function lastTimeRewardApplicable(address _rewardsToken) public view returns (uint256) {
		return MathUpgradeable.min(block.timestamp, rewardData[_rewardsToken].periodFinish);
	}

	function rewardPerToken(address _rewardsToken) public view returns (uint256) {
		if (_totalStake == 0) {
			return rewardData[_rewardsToken].rewardPerTokenStored;
		}
		return
			rewardData[_rewardsToken].rewardPerTokenStored +
			(((lastTimeRewardApplicable(_rewardsToken) - rewardData[_rewardsToken].lastUpdateTime) *
				rewardData[_rewardsToken].rewardRate *
				(10**stakingToken.decimals())) / _totalStake); // from 1e18
	}

	function earned(address _account, address _rewardsToken) public view returns (uint256) {
		uint256 userBalance = _stakes[_account];

		return
			(userBalance * (rewardPerToken(_rewardsToken) - userRewardPerTokenPaid[_account][_rewardsToken])) /
			(10**stakingToken.decimals()) +
			rewards[_account][_rewardsToken];
	}

	function getRewardForDuration(address _rewardsToken) external view returns (uint256) {
		return rewardData[_rewardsToken].rewardRate * rewardData[_rewardsToken].rewardsDuration;
	}

	/* ========== MUTATIVE FUNCTIONS ========== */

	function setRewardsDistributor(address _rewardsToken, address _rewardsDistributor) external onlyGovernance {
		rewardData[_rewardsToken].rewardsDistributor = _rewardsDistributor;
	}

	function _stake(uint256 amount, address account) internal nonReentrant whenNotPaused updateReward(account) {
		require(amount > 0, "Cannot stake 0");
		_totalStake = _totalStake + amount;
		_stakes[account] = _stakes[account] + amount;
		stakingToken.safeTransferFrom(msg.sender, address(this), amount);
		emit Staked(account, amount);
	}

	function _withdraw(uint256 amount, address account) internal nonReentrant updateReward(account) {
		require(amount > 0, "Cannot withdraw 0");
		_totalStake = _totalStake - amount;
		_stakes[account] = _stakes[account] - amount;
		stakingToken.safeTransfer(msg.sender, amount);
		emit Withdrawn(account, amount);
	}

	function stakeFor(address account, uint256 amount) external onlyVault {
		_stake(amount, account);
	}

	function withdrawFor(address account, uint256 amount) external onlyVault {
		_withdraw(amount, account);
	}

	function getRewardFor(address account) public nonReentrant updateReward(account) {
		for (uint256 i; i < rewardTokens.length; i++) {
			address _rewardsToken = rewardTokens[i];
			uint256 reward = rewards[account][_rewardsToken];
			if (reward > 0) {
				rewards[account][_rewardsToken] = 0;
				ERC20Upgradeable(_rewardsToken).safeTransfer(account, reward);
				emit RewardPaid(account, _rewardsToken, reward);
			}
		}
	}

	/* ========== RESTRICTED FUNCTIONS ========== */

	function setGovernance(address _governance) public onlyGovernance {
		governance = _governance;
	}

	function notifyRewardAmount(address _rewardsToken, uint256 reward) external updateReward(address(0)) {
		require(rewardData[_rewardsToken].rewardsDistributor == msg.sender);
		// handle the transfer of reward tokens via `transferFrom` to reduce the number
		// of transactions required and ensure correctness of the reward amount
		ERC20Upgradeable(_rewardsToken).safeTransferFrom(msg.sender, address(this), reward);

		if (block.timestamp >= rewardData[_rewardsToken].periodFinish) {
			rewardData[_rewardsToken].rewardRate = reward / rewardData[_rewardsToken].rewardsDuration;
		} else {
			uint256 remaining = rewardData[_rewardsToken].periodFinish - block.timestamp;
			uint256 leftover = remaining * rewardData[_rewardsToken].rewardRate;
			rewardData[_rewardsToken].rewardRate = (reward + leftover) / rewardData[_rewardsToken].rewardsDuration;
		}

		rewardData[_rewardsToken].lastUpdateTime = block.timestamp;
		rewardData[_rewardsToken].periodFinish = block.timestamp + rewardData[_rewardsToken].rewardsDuration;
		emit RewardAdded(reward);
	}

	function recoverERC20(
		address tokenAddress,
		uint256 tokenAmount,
		address destination
	) external onlyGovernance {
		require(tokenAddress != address(stakingToken), "Cannot withdraw staking token");
		require(rewardData[tokenAddress].lastUpdateTime == 0, "Cannot withdraw reward token");
		ERC20Upgradeable(tokenAddress).safeTransfer(destination, tokenAmount);
		emit Recovered(tokenAddress, tokenAmount);
	}

	function setRewardsDuration(address _rewardsToken, uint256 _rewardsDuration) external {
		require(block.timestamp > rewardData[_rewardsToken].periodFinish, "Reward period still active");
		require(rewardData[_rewardsToken].rewardsDistributor == msg.sender);
		require(_rewardsDuration > 0, "Reward duration must be non-zero");
		rewardData[_rewardsToken].rewardsDuration = _rewardsDuration;
		emit RewardsDurationUpdated(_rewardsToken, rewardData[_rewardsToken].rewardsDuration);
	}

	function mintFor(address _recipient, uint256 _amount) external onlyVault {
		_mint(_recipient, _amount);
	}

	function burnFrom(address _from, uint256 _amount) external onlyVault {
		_burn(_from, _amount);
	}

	function decimals() public view override returns (uint8) {
		return stakingToken.decimals();
	}

	/* ========== MODIFIERS ========== */

	modifier updateReward(address account) {
		for (uint256 i; i < rewardTokens.length; i++) {
			address token = rewardTokens[i];
			rewardData[token].rewardPerTokenStored = rewardPerToken(token);
			rewardData[token].lastUpdateTime = lastTimeRewardApplicable(token);
			if (account != address(0)) {
				rewards[account][token] = earned(account, token);
				userRewardPerTokenPaid[account][token] = rewardData[token].rewardPerTokenStored;
			}
		}
		_;
	}

	modifier onlyGovernance() {
		require(msg.sender == governance, "!gov");
		_;
	}

	modifier onlyVault() {
		require(msg.sender == vault, "!vault");
		_;
	}

	/* ========== EVENTS ========== */

	event RewardAdded(uint256 reward);
	event Staked(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RewardPaid(address indexed user, address indexed rewardsToken, uint256 reward);
	event RewardsDurationUpdated(address token, uint256 newDuration);
	event Recovered(address token, uint256 amount);
}
