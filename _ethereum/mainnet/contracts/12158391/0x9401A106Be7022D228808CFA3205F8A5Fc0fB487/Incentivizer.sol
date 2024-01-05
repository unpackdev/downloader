// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

import "./Math.sol";
import "./SafeMath.sol";

import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Initializable.sol";

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";

import "./RewardsDistributionRecipient.sol";
import "./IStakingRewards.sol";
import "./UniswapV2Library.sol";


contract Incentivizer is IStakingRewards, Ownable, RewardsDistributionRecipient, ReentrancyGuard, Initializable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

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

    modifier whileStakingStopped() {
        require(block.timestamp >= periodFinish, 'notFinished');
        _;
    }

    modifier aboveZero(uint256 value, string memory message) {
        require(value > 0, message);
        _;
    }

    /* ========== INITIALIZER ========== */

    function configure(
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        uint256 _rewardsDuration
    ) external initializer {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
        rewardsDuration = _rewardsDuration;
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view override returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view override returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
        rewardPerTokenStored.add(
            lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
        );
    }

    function earned(address account) public view override returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external view override returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function setRewardsDuration(uint256 _rewardsDuration)
        external
        onlyOwner
        whileStakingStopped
    {
        rewardsDuration = _rewardsDuration;
    }

    function stake(uint256 amount)
        external
        override
        nonReentrant
        aboveZero(amount, "stake0")
        updateReward(msg.sender)
    {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
        public
        override
        nonReentrant
        whileStakingStopped
        aboveZero(amount, "withdraw0")
        updateReward(msg.sender)
    {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward()
        public
        override
        nonReentrant
        updateReward(msg.sender)
    {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external override {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward)
        external
        override
        onlyRewardsDistribution
        updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "tooHighReward");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }
}
