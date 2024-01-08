// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "./MathUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IPartnersStaking.sol";

contract PartnersStaking is IPartnersStaking, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
	using SafeMathUpgradeable for uint256;
	using SafeERC20Upgradeable for IERC20Upgradeable;

	IERC20Upgradeable public stakingToken;
	IERC20Upgradeable public rewardsToken;

	uint256 public rewardPerBlock;
	uint256 public firstBlockWithReward;
	uint256 public lastBlockWithReward;
	uint256 public lastUpdateBlock;
	uint256 public rewardPerTokenStored;
	uint256 public rewardTokensLocked;

	mapping(address => uint256) public userRewardPerTokenPaid;
	mapping(address => uint256) public rewards;

	uint256 public totalStaked;
	mapping(address => uint256) public staked;

	function initialize(address _stakingToken, address _rewardsToken, address _owner)
		external
		override
		initializer
	{
		stakingToken = IERC20Upgradeable(_stakingToken);
		rewardsToken = IERC20Upgradeable(_rewardsToken);

		__Ownable_init();
		transferOwnership(_owner);
		__Pausable_init();
		__ReentrancyGuard_init();
	}

	modifier updateReward(address account) {
		rewardPerTokenStored = rewardPerToken();
		lastUpdateBlock = block.number;
		if (account != address(0)) {
			rewards[account] = earned(account);
			userRewardPerTokenPaid[account] = rewardPerTokenStored;
		}
		_;
	}

	function setRewards(
		uint256 _rewardPerBlock,
		uint256 _startingBlock,
		uint256 _blocksAmount
	) external override onlyOwner updateReward(address(0)) {
		uint256 unlockedTokens = _getFutureRewardTokens();

		rewardPerBlock = _rewardPerBlock;
		firstBlockWithReward = _startingBlock;
		lastBlockWithReward = firstBlockWithReward.add(_blocksAmount).sub(1);

		uint256 lockedTokens = _getFutureRewardTokens();
		rewardTokensLocked = rewardTokensLocked.sub(unlockedTokens).add(lockedTokens);
		require(
			rewardTokensLocked <= rewardsToken.balanceOf(address(this)),
			"Not enough tokens for the rewards"
		);

		emit RewardsSet(_rewardPerBlock, firstBlockWithReward, lastBlockWithReward);
	}

	function recoverNonLockedRewardTokens() external override onlyOwner {
		uint256 nonLockedTokens = rewardsToken.balanceOf(address(this)).sub(rewardTokensLocked);

		rewardsToken.safeTransfer(owner(), nonLockedTokens);
		emit RewardTokensRecovered(nonLockedTokens);
	}

	function pause() external override onlyOwner {
		super._pause();
	}

	function unpause() external override onlyOwner {
		super._unpause();
	}

	function exit() external override {
		withdraw(staked[msg.sender]);
		getReward();
	}

	function stake(uint256 _amount) external override whenNotPaused nonReentrant updateReward(msg.sender) {
		require(_amount > 0, "Stake: can't stake 0");
		require(block.number < lastBlockWithReward, "Stake: staking  period is over");

		totalStaked = totalStaked.add(_amount);
		staked[msg.sender] = staked[msg.sender].add(_amount);
		stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
		emit Staked(msg.sender, _amount);
	}

	function withdraw(uint256 _amount) public override nonReentrant updateReward(msg.sender) {
		require(_amount > 0, "Amount should be greater then 0");
		require(staked[msg.sender] >= _amount, "Insufficient staked amount");
		totalStaked = totalStaked.sub(_amount);
		staked[msg.sender] = staked[msg.sender].sub(_amount);
		stakingToken.safeTransfer(msg.sender, _amount);
		emit Withdrawn(msg.sender, _amount);
	}

	function getReward() public override nonReentrant updateReward(msg.sender) {
		uint256 reward = rewards[msg.sender];
		if (reward > 0) {
			rewards[msg.sender] = 0;
			rewardsToken.safeTransfer(msg.sender, reward);
			rewardTokensLocked = rewardTokensLocked.sub(reward);

			emit RewardPaid(msg.sender, reward);
		}
	}

	function blocksWithRewardsPassed() public view override returns (uint256) {
		uint256 from = MathUpgradeable.max(lastUpdateBlock, firstBlockWithReward);
		uint256 to = MathUpgradeable.min(block.number, lastBlockWithReward);

		return from > to ? 0 : to.sub(from);
	}

	function rewardPerToken() public view override returns (uint256) {
		if (totalStaked == 0 || lastUpdateBlock == block.number) {
			return rewardPerTokenStored;
		}

		uint256 accumulatedReward = blocksWithRewardsPassed().mul(rewardPerBlock).mul(1e18).div(
			totalStaked
		);
		return rewardPerTokenStored.add(accumulatedReward);
	}

	function earned(address _account) public view override returns (uint256) {
		uint256 rewardsDifference = rewardPerToken().sub(userRewardPerTokenPaid[_account]);
		uint256 newlyAccumulated = staked[_account].mul(rewardsDifference).div(1e18);
		return rewards[_account].add(newlyAccumulated);
	}

	function _getFutureRewardTokens() internal view returns (uint256) {
		return _calculateBlocksLeft().mul(rewardPerBlock);
	}

	function _calculateBlocksLeft() internal view returns (uint256) {
		uint256 _from = firstBlockWithReward;
		uint256 _to = lastBlockWithReward;
		if (block.number >= _to) return 0;
		if (block.number < _from) return _to.sub(_from).add(1);
		return _to.sub(block.number);
	}
	function _calculateAnnualReward() public view returns (uint256) {
		uint256 SECONDS_PER_YAER = 31536000;
		if (totalStaked == 0 || block.number < firstBlockWithReward || block.number >= lastBlockWithReward)
			return 0;
		return rewardPerBlock.mul(1e18).mul(SECONDS_PER_YAER).div(totalStaked).div(13);
	}
}
