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

    bool public isPaused;

    // Total staked
    uint256 public totalRewards;
    // Raw amount staked by all users
    uint256 public totalStaked;
    // Total staked with each user multiplier applied
    uint256 public totalWeightedStake;
    // User address => array of the staking info
    mapping(address => StakingInfo[]) public userStakingInfo;

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
    function getUserRewards(address _user, uint256 _stakeNumber) public view returns (uint256) {
        uint256 weightedAmount = rewardsMultiplier.applyMultiplier(
            userStakingInfo[_user][_stakeNumber].stakedAmount,
            userStakingInfo[_user][_stakeNumber].duration
        );
        uint256 rewardsSinceLastUpdate = ((weightedAmount * (rewardPerToken() - userStakingInfo[_user][_stakeNumber].rewardPerTokenPaid)) /
            (10**rewardsTokenDecimals));
        return rewardsSinceLastUpdate + userStakingInfo[_user][_stakeNumber].rewards;
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

    function getUserStakes(address _user) external view returns (StakingInfo[] memory) {
        return userStakingInfo[_user];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function _updateReward(address _user, uint256 _stakeNumber) private {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (_user != address(0)) {
            userStakingInfo[_user][_stakeNumber].rewards = getUserRewards(_user, _stakeNumber);
            userStakingInfo[_user][_stakeNumber].rewardPerTokenPaid = rewardPerTokenStored;
        }
    }

    function stake(
        uint256 _amount,
        StakeTimeOptions _stakeTimeOption,
        uint256 _unstakeTime
    ) external nonReentrant inProgress {
        require(_amount > 0, "FlokiStakingPool::stake: amount = 0");
        uint256 _minimumStakeTimestamp = _stakeTimeOption == StakeTimeOptions.Duration ? block.timestamp + _unstakeTime : _unstakeTime;
        require(_minimumStakeTimestamp > startsAt, "FlokiStakingPool::stake: _minimumStakeTimestamp <= startsAt");
        require(_minimumStakeTimestamp > block.timestamp, "FlokiStakingPool::stake: _minimumStakeTimestamp <= block.timestamp");

        uint256 _stakeDuration = _minimumStakeTimestamp - block.timestamp;

        _updateReward(address(0), 0);
        StakingInfo memory _stakingInfo = StakingInfo({
            stakedAmount: _amount,
            minimumStakeTimestamp: _minimumStakeTimestamp,
            duration: _stakeDuration,
            rewardPerTokenPaid: rewardPerTokenStored,
            rewards: 0
        });
        userStakingInfo[msg.sender].push(_stakingInfo);

        uint256 _stakeNumber = userStakingInfo[msg.sender].length - 1;

        uint256 weightedStake = rewardsMultiplier.applyMultiplier(_amount, _stakeDuration);
        totalWeightedStake += weightedStake;
        totalStaked += _amount;

        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _stakeNumber, _amount);
    }

    function unstake(uint256 _amount, uint256 _stakeNumber) external nonReentrant {
        require(_amount > 0, "FlokiStakingPool::unstake: amount = 0");
        require(_amount <= userStakingInfo[msg.sender][_stakeNumber].stakedAmount, "FlokiStakingPool::unstake: not enough balance");

        _updateReward(msg.sender, _stakeNumber);

        uint256 currentWeightedStake = rewardsMultiplier.applyMultiplier(
            userStakingInfo[msg.sender][_stakeNumber].stakedAmount,
            userStakingInfo[msg.sender][_stakeNumber].duration
        );
        totalWeightedStake -= currentWeightedStake;
        totalStaked -= _amount;

        uint256 penaltyFee = 0;
        if (block.timestamp < userStakingInfo[msg.sender][_stakeNumber].minimumStakeTimestamp) {
            penaltyFee = penaltyFeeCalculator.calculate(_amount, userStakingInfo[msg.sender][_stakeNumber].duration, address(this));
            if (penaltyFee > _amount) {
                penaltyFee = _amount;
            }
        }

        userStakingInfo[msg.sender][_stakeNumber].stakedAmount -= _amount;

        if (userStakingInfo[msg.sender][_stakeNumber].stakedAmount == 0) {
            _claimRewards(msg.sender, _stakeNumber);
            // remove the staking info from array
            userStakingInfo[msg.sender][_stakeNumber] = userStakingInfo[msg.sender][userStakingInfo[msg.sender].length - 1];
            userStakingInfo[msg.sender].pop();
        } else {
            // update the weighted stake
            uint256 newWeightedStake = rewardsMultiplier.applyMultiplier(
                userStakingInfo[msg.sender][_stakeNumber].stakedAmount,
                userStakingInfo[msg.sender][_stakeNumber].duration
            );
            totalWeightedStake += newWeightedStake;
        }

        if (penaltyFee > 0) {
            stakingToken.safeTransfer(BURN_ADDRESS, penaltyFee);
            _amount -= penaltyFee;
        }
        stakingToken.safeTransfer(msg.sender, _amount);
        emit Unstaked(msg.sender, _stakeNumber, _amount);
    }

    function _claimRewards(address _user, uint256 _stakeNumber) private {
        uint256 reward = userStakingInfo[_user][_stakeNumber].rewards;

        if (reward > 0) {
            userStakingInfo[_user][_stakeNumber].rewards = 0;
            rewardsToken.safeTransfer(_user, reward);
            emit RewardPaid(_user, _stakeNumber, reward);
        }
    }

    function claimRewards(uint256 _stakeNumber) external nonReentrant {
        _updateReward(msg.sender, _stakeNumber);
        _claimRewards(msg.sender, _stakeNumber);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function initializeStaking(
        uint256 _startsAt,
        uint256 _rewardsDuration,
        uint256 _amount
    ) external nonReentrant onlyOwner {
        require(_startsAt > block.timestamp, "FlokiStakingPool::initializeStaking: _startsAt must be in the future");
        require(_rewardsDuration > 0, "FlokiStakingPool::initializeStaking: _rewardsDuration = 0");
        require(_amount > 0, "FlokiStakingPool::initializeStaking: _amount = 0");
        require(startsAt == 0, "FlokiStakingPool::initializeStaking: staking already started");

        _updateReward(address(0), 0);

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
        isPaused = true;
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
}
