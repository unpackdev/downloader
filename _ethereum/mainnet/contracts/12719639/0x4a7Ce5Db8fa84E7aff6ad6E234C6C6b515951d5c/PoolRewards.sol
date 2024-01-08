// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Initializable.sol";
import "./ReentrancyGuard.sol";
import "./IPoolRewards.sol";
import "./IVesperPool.sol";

contract PoolRewardsStorage {
    /// Vesper pool address
    address public pool;

    /// Reward token address, mostly it will be VSP
    address public rewardToken;

    /// Once reward end is triggered, owner has to wait at least grace period to
    /// expire before he can withdraw remaining reward.
    uint256 public constant GRACE_PERIOD = 30 days;

    /// Where is current reward period ending
    uint256 public periodFinish;

    /// Current reward rate
    uint256 public rewardRate;

    /// Reward end time
    uint256 public rewardEndTime;

    /// Duration of current reward distribution
    uint256 public rewardDuration;

    /// Last reward drip update time stamp
    uint256 public lastUpdateTime;

    /// Reward per token calculated and stored at last drip update
    uint256 public rewardPerTokenStored;

    /// User => Reward per token stored at last reward update
    mapping(address => uint256) public userRewardPerTokenPaid;

    /// User => Rewards earned till last reward update
    mapping(address => uint256) public rewards;
}

contract PoolRewards is Initializable, IPoolRewards, PoolRewardsStorage, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /**
     * @dev Called by proxy to initialize this contract
     * @param _pool Vesper pool address
     * @param _rewardToken VSP token address
     */
    function initialize(address _pool, address _rewardToken) public initializer {
        pool = _pool;
        rewardToken = _rewardToken;
    }

    /**
     * @dev Notify that reward is added.
     * Also updates reward rate and reward earning period.
     */
    function notifyRewardAmount(uint256 rewardAmount, uint256 _rewardDuration) external override {
        _updateReward(address(0));
        require(msg.sender == IVesperPool(pool).governor(), "not-authorized");
        require(address(rewardToken) != address(0), "rewards-token-not-set");
        require(_rewardDuration > 0, "incorrect-reward-duration");
        rewardDuration = _rewardDuration;
        if (block.timestamp >= periodFinish) {
            rewardRate = rewardAmount / rewardDuration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (rewardAmount + leftover) / rewardDuration;
        }

        uint256 balance = IERC20(rewardToken).balanceOf(address(this));
        require(rewardRate <= (balance / rewardDuration), "rewards-too-high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardDuration;
        rewardEndTime = 0;
        emit RewardAdded(rewardAmount);
    }

    /// @dev Claim earned rewards.
    function claimReward(address account) external override nonReentrant {
        _updateReward(account);
        uint256 reward = rewards[account];
        if (reward != 0 && reward <= IERC20(rewardToken).balanceOf(address(this))) {
            rewards[account] = 0;
            IERC20(rewardToken).safeTransfer(account, reward);
            emit RewardPaid(account, reward);
        }
    }

    /**
     * @notice Updated reward end time.
     * Time at which reward will be ended and governor can withdraw remaining tokens
     */
    function updateRewardEndTime() external override {
        require(msg.sender == IVesperPool(pool).governor(), "not-authorized");
        // Make sure current reward period is over
        uint256 _periodFinish = block.timestamp > periodFinish ? block.timestamp : periodFinish;
        uint256 _rewardEndTime = _periodFinish + GRACE_PERIOD;
        emit UpdatedRewardEndTime(rewardEndTime, _rewardEndTime);
        rewardEndTime = _rewardEndTime;
    }

    /**
     * @notice Withdraw remaining tokens
     * Once reward end time is passed governor can withdraw remaining tokens.
     * @dev rewardRate will be updated to 0
     * @param _toAddress Address where governor want to withdraw tokens
     */
    function withdrawRemaining(address _toAddress) external override {
        require(msg.sender == IVesperPool(pool).governor(), "not-authorized");
        require(rewardEndTime != 0 && block.timestamp > rewardEndTime, "rewards-still-active");
        uint256 _remaining = IERC20(rewardToken).balanceOf(address(this));
        IERC20(rewardToken).safeTransfer(_toAddress, _remaining);
        rewardRate = 0;
        lastUpdateTime = block.timestamp;
        emit RewardEnded(_toAddress, _remaining);
    }

    /**
     * @dev Updated reward for given account. Only Pool can call
     */
    function updateReward(address _account) external override {
        require(msg.sender == pool, "Only pool can update reward");
        _updateReward(_account);
    }

    function rewardForDuration() external view override returns (uint256) {
        return rewardRate * rewardDuration;
    }

    /// @dev Returns claimable reward amount.
    function claimable(address account) public view override returns (uint256) {
        uint256 _balance = IERC20(pool).balanceOf(account);
        uint256 _rewardPerTokenAvailable = rewardPerToken() - userRewardPerTokenPaid[account];
        uint256 _rewardsEarnedSinceLastUpdate = (_balance * _rewardPerTokenAvailable) / 1e18;
        return rewards[account] + _rewardsEarnedSinceLastUpdate;
    }

    /// @dev Returns timestamp of last reward update
    function lastTimeRewardApplicable() public view override returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view override returns (uint256) {
        if (IERC20(pool).totalSupply() == 0) {
            return rewardPerTokenStored;
        }

        uint256 _timeSinceLastUpdate = lastTimeRewardApplicable() - lastUpdateTime;
        uint256 _rewardsSinceLastUpdate = _timeSinceLastUpdate * rewardRate;
        uint256 _rewardsPerTokenSinceLastUpdate = (_rewardsSinceLastUpdate * 1e18) / IERC20(pool).totalSupply();
        return rewardPerTokenStored + _rewardsPerTokenSinceLastUpdate;
    }

    function _updateReward(address _account) private {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (_account != address(0)) {
            rewards[_account] = claimable(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }
    }
}
