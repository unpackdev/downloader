// SPDX-License-Identifier: MIT
pragma solidity =0.7.4;

import "./Math.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuard.sol";
import "./OwnableUpgradeable.sol";

import "./IContractsRegistry.sol";
import "./IBMIStaking.sol";

contract LiquidityMiningStaking is OwnableUpgradeable, ReentrancyGuard {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;
	using SafeERC20Upgradeable for IERC20Upgradeable;

	IERC20 public rewardsToken;
	IERC20 public stakingToken;
	IBMIStaking public bmiStaking;
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

	address public newLiquidityMiningStakingAddress;

	event RewardsSet(
		uint256 rewardPerBlock,
		uint256 firstBlockWithReward,
		uint256 lastBlockWithReward
	);
	event Staked(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RewardPaid(address indexed user, uint256 reward);
	event RewardRestaked(
		address indexed user,
		uint256 reward,
		uint256 stakingTokens
	);
	event RewardTokensRecovered(uint256 amount);
	event StakingMigrated(address staker, uint256 amount);

	function __LiquidityMiningStaking_init()
		external
		initializer
	{
		__Ownable_init();
	}

	function setDependencies(IContractsRegistry _contractsRegistry) external onlyOwner {
		rewardsToken = IERC20(_contractsRegistry.getBMIContract());
		bmiStaking = IBMIStaking(_contractsRegistry.getBMIStakingContract());
		stakingToken = IERC20(_contractsRegistry.getUniswapBMIToETHPairContract());
	}

	function setNewLiquidityMiningStaking(address _newLiquidityMiningStakingAddress) external onlyOwner {
        newLiquidityMiningStakingAddress = _newLiquidityMiningStakingAddress;
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

	function blocksWithRewardsPassed() public view returns (uint256) {
		uint256 from = Math.max(lastUpdateBlock, firstBlockWithReward);
		uint256 to = Math.min(block.number, lastBlockWithReward);

		return from > to ? 0 : to.sub(from);
	}

	function rewardPerToken() public view returns (uint256) {
		if (totalStaked == 0) {
			return rewardPerTokenStored;
		}

		uint256 accumulatedReward =
			blocksWithRewardsPassed().mul(rewardPerBlock).mul(1e18).div(
				totalStaked
			);
		return rewardPerTokenStored.add(accumulatedReward);
	}

	function earned(address _account) public view returns (uint256) {
		uint256 rewardsDifference =
			rewardPerToken().sub(userRewardPerTokenPaid[_account]);
		uint256 newlyAccumulated =
			staked[_account].mul(rewardsDifference).div(1e18);
		return rewards[_account].add(newlyAccumulated);
	}

	function migrate()
		external
		updateReward(msg.sender) 
	{
        require(newLiquidityMiningStakingAddress != address(0), "Can't migrate to zero address");

		getReward();

		uint256 amount = staked[msg.sender];
		require(amount > 0, "Insufficient staked amount");

		totalStaked = totalStaked.sub(amount);
		staked[msg.sender] = 0;

        stakingToken.transfer(newLiquidityMiningStakingAddress, amount);

        (bool succ, ) =
            newLiquidityMiningStakingAddress.call(
                abi.encodeWithSignature("stakeFor(address,uint256)", msg.sender, amount)
            );

        require(succ, "Something went wrong");

		emit StakingMigrated(msg.sender, amount);
    }

	function stake(uint256 _amount)
		external
		nonReentrant
		updateReward(msg.sender)
	{
		require(_amount > 0, "Amount should be greater then 0");
		totalStaked = totalStaked.add(_amount);
		staked[msg.sender] = staked[msg.sender].add(_amount);
		stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
		emit Staked(msg.sender, _amount);
	}

	function withdraw(uint256 _amount)
		public
		nonReentrant
		updateReward(msg.sender)
	{
		require(_amount > 0, "Amount should be greater then 0");
		require(staked[msg.sender] >= _amount, "Insufficient staked amount");
		totalStaked = totalStaked.sub(_amount);
		staked[msg.sender] = staked[msg.sender].sub(_amount);
		stakingToken.safeTransfer(msg.sender, _amount);
		emit Withdrawn(msg.sender, _amount);
	}

	function getReward() public nonReentrant updateReward(msg.sender) {
		uint256 reward = rewards[msg.sender];
		if (reward > 0) {
			rewards[msg.sender] = 0;
			rewardsToken.safeTransfer(msg.sender, reward);
			rewardTokensLocked = rewardTokensLocked.sub(reward);

			emit RewardPaid(msg.sender, reward);
		}
	}

	function restake() external nonReentrant updateReward(msg.sender) {
		uint256 reward = rewards[msg.sender];
		if (reward > 0) {
			rewards[msg.sender] = 0;

			rewardsToken.approve(address(bmiStaking), reward);
			bmiStaking.stake(reward);
			rewardTokensLocked = rewardTokensLocked.sub(reward);

			IERC20Upgradeable bmiStakingToken = IERC20Upgradeable(bmiStaking.stkBMIToken());
			uint256 stakingTokens = bmiStakingToken.balanceOf(address(this));
			bmiStakingToken.safeTransfer(msg.sender, stakingTokens);
			emit RewardRestaked(msg.sender, reward, stakingTokens);
		}
	}

	function exit() external {
		withdraw(staked[msg.sender]);
		getReward();
	}

	function setRewards(
		uint256 _rewardPerBlock,
		uint256 _startingBlock,
		uint256 _blocksAmount
	) external onlyOwner updateReward(address(0)) {
		uint256 unlockedTokens = _getFutureRewardTokens();

		rewardPerBlock = _rewardPerBlock;
		firstBlockWithReward = _startingBlock;
		lastBlockWithReward = firstBlockWithReward.add(_blocksAmount).sub(1);

		uint256 lockedTokens = _getFutureRewardTokens();
		rewardTokensLocked = rewardTokensLocked.sub(unlockedTokens).add(
			lockedTokens
		);
		require(
			rewardTokensLocked <= rewardsToken.balanceOf(address(this)),
			"Not enough tokens for the rewards"
		);

		emit RewardsSet(
			_rewardPerBlock,
			firstBlockWithReward,
			lastBlockWithReward
		);
	}

	function recoverNonLockedRewardTokens() external onlyOwner {
		uint256 nonLockedTokens =
			rewardsToken.balanceOf(address(this)).sub(rewardTokensLocked);

		rewardsToken.safeTransfer(owner(), nonLockedTokens);
		emit RewardTokensRecovered(nonLockedTokens);
	}

	function _getFutureRewardTokens() internal view returns (uint256) {
		uint256 blocksLeft =
			_calculateBlocksLeft(firstBlockWithReward, lastBlockWithReward);
		return blocksLeft.mul(rewardPerBlock);
	}

	function _calculateBlocksLeft(uint256 _from, uint256 _to)
		internal
		view
		returns (uint256)
	{
		if (block.number >= _to) return 0;
		if (block.number < _from) return _to.sub(_from).add(1);
		return _to.sub(block.number);
	}
}
