// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";

import "./SafeERC20.sol";
import "./Math.sol";

import "./IUserHook.sol";

contract FuturesRewardPool is UUPSUpgradeable, OwnableUpgradeable, IUserHook {
    using SafeERC20 for IERC20;

    IERC20 public rewardToken;
    uint256 public duration;

    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public historicalRewards;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;

    event RewardAdded(uint256 reward);
    event UpdateStaked(address indexed user, uint256 oldAmount, uint256 newAmount);
    event RewardPaid(address indexed user, uint256 reward);

    address public basePool;

    constructor() {
        _disableInitializers();
    }

    function initialize(address reward_, address basePool_) external initializer {
        __Ownable_init(_msgSender());
        duration = 14 days;
        rewardToken = IERC20(reward_);
        basePool = basePool_;
    }

    function updateReward(address account) internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + ((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18) / totalSupply;
    }

    function earned(address account) public view returns (uint256) {
        return (balanceOf[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18 + rewards[account];
    }

    function updateUser(address _account, FuturesUser memory userData) external {
        require(msg.sender == address(basePool), "!authorized");
        getReward(_account);

        uint oldStaked = balanceOf[_account];
        totalSupply -= oldStaked;
        uint newAmount = userData.current_balance;
        balanceOf[_account] = newAmount;
        totalSupply += newAmount;

        emit UpdateStaked(_account, oldStaked, newAmount);
    }

    function getReward(address _account) internal {
        updateReward(_account);
        uint256 reward = earned(_account);
        if (reward > 0) {
            rewards[_account] = 0;
            rewardToken.safeTransfer(_account, reward);
            emit RewardPaid(_account, reward);
        }
    }

    function getReward() external {
        getReward(msg.sender);
    }

    function notifyRewardAmount(uint256 _reward) external onlyOwner {
        updateReward(address(0));
        historicalRewards += _reward;
        if (block.timestamp >= periodFinish) {
            rewardRate = _reward / duration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (_reward + leftover) / duration;
        }

        uint balance = rewardToken.balanceOf(address(this));
        require(rewardRate <= balance / duration, "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + duration;
        emit RewardAdded(_reward);
    }

    function setRewardDuartion(uint256 _duration) external onlyOwner {
        duration = _duration;
    }

    function recoverToken(address[] calldata tokens) external onlyOwner {
        unchecked {
            for (uint8 i; i < tokens.length; i++) {
                IERC20(tokens[i]).safeTransfer(msg.sender, IERC20(tokens[i]).balanceOf(address(this)));
            }
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
