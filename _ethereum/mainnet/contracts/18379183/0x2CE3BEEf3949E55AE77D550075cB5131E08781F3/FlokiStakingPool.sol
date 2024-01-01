// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

import "./IMultiplier.sol";
import "./IPenaltyFee.sol";
import "./IStakingPool.sol";

contract FlokiStakingPool is ReentrancyGuard, IStakingPool {
    using SafeERC20 for IERC20;

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardsToken;
    uint256 public immutable rewardsTokenDecimals;

    IMultiplier public immutable override rewardsMultiplier;
    IPenaltyFee public immutable override penaltyFeeCalculator;

    address public owner;

    // Duration of the rewards (in seconds)
    uint256 public rewardsDuration;
    // Timestamp of when the staking starts
    uint256 public startsAt;
    // Timestamp of when the staking ends
    uint256 public endsAt;
    // Timestamp of the reward updated
    uint256 public lastUpdateTime;
    // Reward per second (total rewards / duration)
    uint256 public rewardRatePerSec;
    // Reward per token stored
    uint256 public rewardPerTokenStored;
    // Reward per token paid
    mapping(address => uint256) public userRewardPerTokenPaid;
    // User address => rewards to be claimed
    mapping(address => uint256) public rewards;

    bool public isPaused;

    // Total staked
    uint256 public totalRewards;
    // Raw amount staked by all users
    uint256 public totalStaked;
    // Total staked with each user multiplier applied
    uint256 public totalWeightedStake;
    // User address => original staked amount
    mapping(address => uint256) public override balanceOf;
    // User address => Unstake timestamp
    mapping(address => uint256) public override minimumStakeTimestamp;
    // User address => Stake Duration
    mapping(address => uint256) public override userStakeDuration;

    // it has to be evaluated on a user basis

    enum StakeTimeOptions {
        Duration,
        EndTime
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event TokenRecovered(address token, uint256 amount);

    constructor(
        address _stakingToken,
        address _rewardToken,
        uint256 _rewardsTokenDecimals,
        address _multiplier,
        address _penaltyFeeCalculator
    ) {
        owner = msg.sender;
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardToken);
        rewardsTokenDecimals = _rewardsTokenDecimals;
        rewardsMultiplier = IMultiplier(_multiplier);
        penaltyFeeCalculator = IPenaltyFee(_penaltyFeeCalculator);
    }

    /* ========== VIEWS ========== */

    /**
     * Calculates how much rewards a user has earned up to current block, every time the user stakes/unstakes/withdraw.
     * We update "rewards[_user]" with how much they are entitled to, up to current block.
     * Next time we calculate how much they earned since last update and accumulate on rewards[_user].
     */
    function getUserRewards(address _user) public view returns (uint256) {
        uint256 stakedAmount = rewardsMultiplier.applyMultiplier(balanceOf[_user], _user, address(this));
        uint256 rewardsSinceLastUpdate = ((stakedAmount * (rewardPerToken() - userRewardPerTokenPaid[_user])) / (10**rewardsTokenDecimals));
        return rewardsSinceLastUpdate + rewards[_user];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < endsAt ? block.timestamp : endsAt;
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardPerTokenStored;
        }
        uint256 howLongSinceLastTime = lastTimeRewardApplicable() - lastUpdateTime;
        return rewardPerTokenStored + ((rewardRatePerSec * howLongSinceLastTime * (10**rewardsTokenDecimals)) / totalWeightedStake);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(
        uint256 _amount,
        StakeTimeOptions _stakeTimeOption,
        uint256 _unstakeTime
    ) external nonReentrant inProgress {
        require(balanceOf[msg.sender] == 0, "FlokiStakingPool::stakeMore: active stake, use stakeMore");
        require(_amount > 0, "FlokiStakingPool::stake: amount = 0");
        uint256 _minimumStakeTimestamp = _stakeTimeOption == StakeTimeOptions.Duration ? block.timestamp + _unstakeTime : _unstakeTime;
        require(_minimumStakeTimestamp > startsAt, "FlokiStakingPool::stake: _minimumStakeTimestamp <= startsAt");
        require(_minimumStakeTimestamp > block.timestamp, "FlokiStakingPool::stake: _minimumStakeTimestamp <= block.timestamp");
        require(_minimumStakeTimestamp <= endsAt, "FlokiStakingPool::stake: _minimumStakeTimestamp > endsAt");
        minimumStakeTimestamp[msg.sender] = _minimumStakeTimestamp;
        userStakeDuration[msg.sender] = _stakeTimeOption == StakeTimeOptions.Duration ? _unstakeTime : _unstakeTime - block.timestamp;
        _updatePool(_amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }

    function stakeMore(uint256 _amount) external nonReentrant inProgress {
        require(_amount > 0, "FlokiStakingPool::stakeMore: amount = 0");
        require(balanceOf[msg.sender] > 0, "FlokiStakingPool::stakeMore: has not staked yet");
        _updatePool(_amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }

    function _updatePool(uint256 stakedAmount) private updateReward(msg.sender) {
        uint256 oldWeightedStake = rewardsMultiplier.applyMultiplier(balanceOf[msg.sender], msg.sender, address(this));
        balanceOf[msg.sender] += stakedAmount;
        uint256 weightedStake = rewardsMultiplier.applyMultiplier(balanceOf[msg.sender], msg.sender, address(this));
        totalWeightedStake += weightedStake;
        totalWeightedStake -= oldWeightedStake;
        totalStaked += stakedAmount;
    }

    function unstake(uint256 _amount) external nonReentrant updateReward(msg.sender) {
        require(_amount > 0, "FlokiStakingPool::unstake: amount = 0");
        require(_amount <= balanceOf[msg.sender], "FlokiStakingPool::unstake: not enough balance");

        uint256 currentWeightedStake = rewardsMultiplier.applyMultiplier(balanceOf[msg.sender], msg.sender, address(this));
        totalWeightedStake -= currentWeightedStake;
        totalStaked -= _amount;

        uint256 penaltyFee = 0;
        if (block.timestamp < minimumStakeTimestamp[msg.sender]) {
            penaltyFee = penaltyFeeCalculator.calculate(msg.sender, _amount, address(this));
            if (penaltyFee > _amount) {
                penaltyFee = _amount;
            }
        }

        balanceOf[msg.sender] -= _amount;
        if (balanceOf[msg.sender] == 0) {
            delete minimumStakeTimestamp[msg.sender];
            delete userStakeDuration[msg.sender];
        }

        uint256 newStake = rewardsMultiplier.applyMultiplier(balanceOf[msg.sender], msg.sender, address(this));
        totalWeightedStake += newStake;

        if (penaltyFee > 0) {
            stakingToken.safeTransfer(BURN_ADDRESS, penaltyFee);
            _amount -= penaltyFee;
        }
        stakingToken.safeTransfer(msg.sender, _amount);
        emit Unstaked(msg.sender, _amount);
    }

    function claimRewards() external nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function initializeStaking(
        uint256 _startsAt,
        uint256 _rewardsDuration,
        uint256 _amount
    ) external nonReentrant onlyOwner updateReward(address(0)) {
        require(_startsAt > block.timestamp, "FlokiStakingPool::initializeStaking: _startsAt must be in the future");
        require(_rewardsDuration > 0, "FlokiStakingPool::initializeStaking: _rewardsDuration = 0");
        require(_amount > 0, "FlokiStakingPool::initializeStaking: _amount = 0");
        require(startsAt == 0, "FlokiStakingPool::initializeStaking: staking already started");
        rewardsDuration = _rewardsDuration;
        startsAt = _startsAt;
        endsAt = _startsAt + _rewardsDuration;

        // add the amount to the pool
        uint256 initialAmount = rewardsToken.balanceOf(address(this));
        rewardsToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 actualAmount = rewardsToken.balanceOf(address(this)) - initialAmount;
        totalRewards = actualAmount;
        rewardRatePerSec = actualAmount / _rewardsDuration;

        // set the staking to in progress
        isPaused = false;
    }

    function resumeStaking() external onlyOwner {
        require(rewardRatePerSec > 0, "FlokiStakingPool::startStaking: reward rate = 0");
        require(isPaused, "FlokiStakingPool::startStaking: staking already started");
        isPaused = false;
    }

    function pauseStaking() external onlyOwner {
        require(!isPaused, "FlokiStakingPool::pauseStaking: staking already paused");
        isPaused = false;
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(stakingToken), "Cannot withdraw the staking token");
        require(tokenAddress != address(rewardsToken), "Cannot withdraw the reward token");
        IERC20(tokenAddress).safeTransfer(owner, tokenAmount);
        emit TokenRecovered(tokenAddress, tokenAmount);
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        address currentOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(currentOwner, _newOwner);
    }

    /* ========== MODIFIERS ========== */

    modifier inProgress() {
        require(!isPaused, "FlokiStakingPool::initialized: staking is paused");
        require(startsAt <= block.timestamp, "FlokiStakingPool::initialized: staking has not started yet");
        require(endsAt > block.timestamp, "FlokiStakingPool::notFinished: staking has finished");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "FlokiStakingPool::onlyOwner: not authorized");
        _;
    }

    modifier updateReward(address _user) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (_user != address(0)) {
            rewards[_user] = getUserRewards(_user);
            userRewardPerTokenPaid[_user] = rewardPerTokenStored;
        }
        _;
    }
}
