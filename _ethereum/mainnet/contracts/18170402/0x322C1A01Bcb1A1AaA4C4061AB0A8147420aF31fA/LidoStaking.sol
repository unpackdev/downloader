// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

contract LidoStaking is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Immutable variables for staking and rewards tokens
    address public stakingToken;
    address public rewardsToken;
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

    mapping(address => bool) public blackListAccounts;

    /********************************************/
    /****************** EVENTS ******************/
    /********************************************/

    event StakeToken(address indexed user, uint256 amount, uint256 time);
    event ClaimReward(address indexed user, address indexed token, uint256 amount, uint256 time);
    event NotifyRewardChanged(address indexed token, uint256 amount, uint256 time);
    event RewardsDurationChanged(uint256 duration);
    event GovChanged(address indexed gov);

    function initialize(address _stakingToken, address _rewardToken) public initializer {
        __Ownable_init();

        stakingToken = _stakingToken;
        rewardsToken = _rewardToken;
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

    // Calculates and returns the earned rewards for a user
    function earned(address _account) public view returns (uint256) {
        return
            ((balanceOf[_account] * (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18) + rewards[_account];
    }

    /****************************************************************/
    /****************** EXTERNAL PUBLIC FUNCTIONS  ******************/
    /****************************************************************/

    // Allows users to stake the total balance of tokens
    function stake(address _account, uint256 _balance) external updateReward(_account) {
        // LDS_OST: only staking token
        require(stakingToken == msg.sender, "LDS_OST");
        // LDS_AZ: address is zero
        require(_account != address(0), "LDS_AZ");

        uint256 oldBalance = balanceOf[_account];

        // LDS_TSLUB: total supply is lower than user balance
        require(totalSupply >= oldBalance, "LDS_TSLUB");

        // restake after account balance changed
        totalSupply = totalSupply + _balance - oldBalance;
        balanceOf[_account] = _balance;

        emit StakeToken(_account, _balance, block.timestamp);
    }

    function refreshReward(address _account) public updateReward(_account) {}

    // Allows users to claim their earned rewards
    function getReward() external updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            _safeTokenTransfer(IERC20Upgradeable(rewardsToken), msg.sender, reward);
        }

        emit ClaimReward(msg.sender, rewardsToken, reward, block.timestamp);
    }

    // Allows the owner to set the mining rewards.
    function notifyRewardAmount(uint256 _amount) external updateReward(address(0)) {
        // LDS_OG: only gov
        require(gov == msg.sender, "LDS_OG");

        if (_amount > 0) {
            IERC20Upgradeable(rewardsToken).safeTransferFrom(msg.sender, address(this), _amount);
        }

        if (block.timestamp >= finishAt) {
            rewardRate = _amount / duration;
        } else {
            uint256 remainingRewards = (finishAt - block.timestamp) * rewardRate;
            rewardRate = (_amount + remainingRewards) / duration;
        }

        // LDS_RRZ: reward rate is zero
        require(rewardRate > 0, "LDS_RRZ");

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;

        emit NotifyRewardChanged(rewardsToken, _amount, block.timestamp);
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

    // Allows the owner to emergency withdraw the reward tokens' balances on the contract
    function emergencyWithdraw(IERC20Upgradeable token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        // LDS_TBN: token balance is null
        require(balance > 0, "LDS_TBN");
        _safeTokenTransfer(token, msg.sender, balance);
    }

    // Allows the owner to add the account into the black list
    function setBlackListAccounts(address[] calldata _contracts, bool[] calldata _bools) external onlyOwner {
        // LDS_IL: invalid length
        require(_contracts.length == _bools.length, "LDS_IL");

        for (uint256 i = 0; i < _contracts.length; i++) {
            address account = _contracts[i];
            blackListAccounts[account] = _bools[i];

            // if the user was added into blacklist, then clear all the previous rewards
            if (_bools[i] == true) {
                refreshReward(account);

                uint256 accountStakedAmount = balanceOf[account];
                totalSupply -= accountStakedAmount;

                balanceOf[account] = 0;

                uint256 reward = rewards[account];
                if (reward > 0) {
                    rewards[account] = 0;
                    _safeTokenTransfer(IERC20Upgradeable(rewardsToken), gov, reward);
                }
            }
        }
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
