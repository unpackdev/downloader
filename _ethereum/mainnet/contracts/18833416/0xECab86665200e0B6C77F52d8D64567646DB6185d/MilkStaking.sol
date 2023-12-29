//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

contract MilkStaking is OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event RewardsDistributionUpdated(address newDistribution);

    /* ========== STATE VARIABLES ========== */

    struct Stake {
        uint256 amount;
        uint256 stakedAt;
    }

    IERC20Upgradeable public xIXT;
    IERC20Upgradeable public milk;
    uint256 public lockPeriod;
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    address public rewardsDistribution;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private milkStaked;
    mapping(address => uint256) private userMilkStaked;
    mapping(address => Stake[]) public userIndividualMilkStakes;

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _rewardsDistribution,
        address _xIXT,
        address _milk,
        uint256 _rewardsDuration,
        uint256 _lockPeriod
    ) external initializer {
        require(_xIXT != address(0), "rewardToken must not 0x");
        require(_milk != address(0), "milk must not 0x");
        require(_rewardsDistribution != address(0), "rewardDistribution must not 0x");
        require(_rewardsDuration != 0, "rewardsDuration must not 0");

        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        xIXT = IERC20Upgradeable(_xIXT);
        milk = IERC20Upgradeable(_milk);
        rewardsDistribution = _rewardsDistribution;
        rewardsDuration = _rewardsDuration;
        lockPeriod = _lockPeriod;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Cannot stake 0");

        _updateRewards(msg.sender);
        userMilkStaked[msg.sender] += amount;
        userIndividualMilkStakes[msg.sender].push(Stake({amount: amount, stakedAt: block.timestamp}));

        milkStaked += amount;

        milk.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant {
        require(amount > 0, "Cannot withdraw 0");

        _checkEnoughTokensUnlocked(msg.sender, amount);
        _updateRewards(msg.sender);

        milkStaked -= amount;
        userMilkStaked[msg.sender] -= amount;
        milk.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public nonReentrant {
        _updateRewards(msg.sender);
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            xIXT.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external {
        withdraw(userMilkStaked[msg.sender]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward) external {
        require(msg.sender == rewardsDistribution, "Not rewardsDistribution");
        _updateRewards(address(0));

        xIXT.safeTransferFrom(msg.sender, address(this), reward);
        if (block.timestamp >= periodFinish) {
            rewardRate = reward / rewardsDuration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / rewardsDuration;
        }

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;
        emit RewardAdded(reward);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(block.timestamp > periodFinish, "Previous rewards period must be complete before changing the duration for the new period");
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(_rewardsDuration);
    }

    function setRewardsDistribution(address _rewardsDistribution) external onlyOwner {
        require(_rewardsDistribution != address(0), "rewardDistribution must not 0x");
        rewardsDistribution = _rewardsDistribution;
        emit RewardsDistributionUpdated(_rewardsDistribution);
    }

    function setMilk(IERC20Upgradeable _milk) external onlyOwner {
        milk = _milk;
    }

    function setXIXT(IERC20Upgradeable _xIXT) external onlyOwner {
        xIXT = _xIXT;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setLockPeriod(uint256 _lockPeriod) external onlyOwner {
        lockPeriod = _lockPeriod;
    }

    function _updateRewards(address _walletAddress) internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();

        if (_walletAddress != address(0)) {
            rewards[_walletAddress] = earned(_walletAddress);
            userRewardPerTokenPaid[_walletAddress] = rewardPerTokenStored;
        }
    }

    function _checkEnoughTokensUnlocked(address _user, uint256 _amount) internal {
        Stake[] memory userStaked = userIndividualMilkStakes[_user];

        uint256 remaining = _amount;
        for (uint256 i; i < userStaked.length; i++) {
            if (block.timestamp > (userStaked[i].stakedAt + lockPeriod)) {
                if (remaining >= userStaked[i].amount) {
                    remaining -= userStaked[i].amount;
                    _removeFromArray(0, userIndividualMilkStakes[_user]);
                } else {
                    userIndividualMilkStakes[_user][i].amount -= remaining;
                    remaining = 0;
                    return;
                }
            }
        }
        require(remaining == 0, "ENERGY STAKING: NOT_ENOUGH_TOKENS_UNLOCKED");
    }

    function _removeFromArray(uint256 _position, Stake[] storage _arr) internal {
        for (uint256 i = _position; i < _arr.length - 1; i++) {
            _arr[i] = _arr[i + 1];
        }
        _arr.pop();
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return milkStaked;
    }

    function balanceOf(address account) external view returns (uint256) {
        return userMilkStaked[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint256) {
        if (milkStaked == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + (((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18) / milkStaked);
    }

    function earned(address account) public view returns (uint256) {
        return (userMilkStaked[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18 + rewards[account];
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate * rewardsDuration;
    }

    function getUserMilkStakes(address _user) external view returns (Stake[] memory) {
        return userIndividualMilkStakes[_user];
    }
}
