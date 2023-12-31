// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./IesToken.sol";
import "./IBoost.sol";

contract LPStaking is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Immutable variables for staking and rewards tokens
    IERC20Upgradeable public stakingToken;
    IesToken public rewardsToken;
    IBoost public boost;
    address public gov;

    // Duration of rewards to be paid out
    uint256 public duration;
    // Timestamp of when the rewards finish
    uint256 public finishAt;
    // Minimum of last updated time and reward finish time
    uint256 public updatedAt;
    // Reward to be paid out per second
    uint256 public rewardRate;
    // Sum of (reward rate * dt * 1e18 / total supply)
    uint256 public rewardPerTokenStored;
    // User address => rewardPerTokenStored
    mapping(address => uint256) public userRewardPerTokenPaid;
    // User address => rewards to be claimed
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public userUpdatedAt;

    // Total staked
    uint256 public totalSupply;
    // User address => staked amount
    mapping(address => uint256) public balanceOf;

    /********************************************/
    /****************** EVENTS ******************/
    /********************************************/

    event StakeToken(address indexed user, uint256 amount, uint256 time);
    event UnStakeToken(address indexed user, uint256 amount, uint256 time);
    event ClaimReward(address indexed user, address indexed token, uint256 amount, uint256 time);
    event NotifyRewardChanged(address indexed token, uint256 amount, uint256 time);
    event RewardsDurationChanged(uint256 duration);
    event BoostChanged(address indexed boost);
    event GovChanged(address indexed gov);

    function initialize(address _stakingToken, address _rewardToken, address _boost) public initializer {
        __Ownable_init();

        stakingToken = IERC20Upgradeable(_stakingToken);
        rewardsToken = IesToken(_rewardToken);
        boost = IBoost(_boost);
        gov = msg.sender;
    }

    /***********************************************/
    /****************** MODIFIERS ******************/
    /***********************************************/

    // Update user's claimable reward data and record the timestamp.
    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
            userUpdatedAt[_account] = block.timestamp;
        }
        _;
    }

    /*******************************************/
    /****************** VIEWS ******************/
    /*******************************************/

    // Returns the last time the reward was applicable
    function lastTimeRewardApplicable() public view returns (uint256) {
        return _min(finishAt, block.timestamp);
    }

    // Calculates and returns the reward per token
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored + (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) / totalSupply;
    }

    function getBoost(address _account) public view returns (uint256) {
        if (balanceOf[_account] == 0) return 100 * 1e18;

        uint256 needLockedAmount = boost.getAmountNeedLocked(_account, balanceOf[_account], totalSupply);

        (uint256 currentLockAmount, , , ) = boost.userLockStatus(_account);
        uint256 maxBoost = boost.getUserBoost(_account, userUpdatedAt[_account], finishAt);

        if (currentLockAmount >= needLockedAmount) {
            return 100 * 1e18 + maxBoost;
        }

        return 100 * 1e18 + (maxBoost * currentLockAmount) / needLockedAmount;
    }

    // Calculates and returns the earned rewards for a user
    function earned(address _account) public view returns (uint256) {
        return
            ((balanceOf[_account] * getBoost(_account) * (rewardPerToken() - userRewardPerTokenPaid[_account])) /
                1e38) + rewards[_account];
    }

    /****************************************************************/
    /****************** EXTERNAL PUBLIC FUNCTIONS  ******************/
    /****************************************************************/

    // Allows users to stake a specified amount of tokens
    function stake(uint256 _amount) external updateReward(msg.sender) {
        // LPS_SAZ: stake amount is zero
        require(_amount > 0, "LPS_SAZ");

        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;

        emit StakeToken(msg.sender, _amount, block.timestamp);
    }

    // Allows users to unstake a specified amount of staked tokens
    function unstake(uint256 _amount) external updateReward(msg.sender) {
        // LPS_WAZ: unstake amount is zero
        require(_amount > 0, "LPS_WAZ");

        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        _safeTokenTransfer(stakingToken, msg.sender, _amount);

        emit UnStakeToken(msg.sender, _amount, block.timestamp);
    }

    function refreshReward(address _account) external updateReward(_account) {}

    // Allows users to claim their earned rewards
    function getReward() external updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.mint(msg.sender, reward);
        }

        emit ClaimReward(msg.sender, address(rewardsToken), reward, block.timestamp);
    }

    // Allows the owner to set the mining rewards.
    function notifyRewardAmount(uint256 _amount) external updateReward(address(0)) {
        // LPS_OG: only gov
        require(gov == msg.sender, "LPS_OG");

        if (block.timestamp >= finishAt) {
            rewardRate = _amount / duration;
        } else {
            uint256 remainingRewards = (finishAt - block.timestamp) * rewardRate;
            rewardRate = (_amount + remainingRewards) / duration;
        }

        // LPS_RRZ: reward rate is zero
        require(rewardRate > 0, "LPS_RRZ");

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;

        emit NotifyRewardChanged(address(rewardsToken), _amount, block.timestamp);
    }

    /****************************************************************/
    /*********************** OWNABLE FUNCTIONS  *********************/
    /****************************************************************/

    // Allows the owner to set the gov contract address
    function setGov(address _gov) external onlyOwner {
        gov = _gov;
        emit GovChanged(gov);
    }

    // Allows the owner to set the rewards duration
    function setRewardsDuration(uint256 _duration) external onlyOwner {
        duration = _duration;
        emit RewardsDurationChanged(duration);
    }

    // Allows the owner to set the boost contract address
    function setBoost(address _boost) external onlyOwner {
        boost = IBoost(_boost);
        emit BoostChanged(_boost);
    }

    function emergencyWithdraw(IERC20Upgradeable token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        // LPS_TBN: token balance is null
        require(balance > 0, "LPS_TBN");
        _safeTokenTransfer(token, msg.sender, balance);
    }

    /********************************************************/
    /****************** INTERNAL FUNCTIONS ******************/
    /********************************************************/

    function _safeTokenTransfer(IERC20Upgradeable token, address to, uint256 amount) internal {
        if (amount > 0) {
            uint256 tokenBal = token.balanceOf(address(this));
            if (amount > tokenBal) {
                token.safeTransfer(to, tokenBal);
            } else {
                token.safeTransfer(to, amount);
            }
        }
    }

    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }
}
