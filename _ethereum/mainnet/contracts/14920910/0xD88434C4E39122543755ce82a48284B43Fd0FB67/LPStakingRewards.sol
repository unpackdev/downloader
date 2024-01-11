// SPDX-License-Identifier: MIT

// Based on https://github.com/Synthetixio/synthetix/blob/master/contracts/StakingRewards.sol

pragma solidity ^0.8;

import "./Ownable.sol";
import "./IERC20Min.sol";

contract LPStakingRewards is Ownable {
    address public immutable treasuryAddress;
    IERC20Min public immutable stakingToken;
    IERC20Min public immutable rewardsToken;
    uint256 public immutable periodFinish;

    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(
        address _treasuryAddress,
        address _stakingToken,
        address _rewardsToken,
        uint256 _rewardRate,
        uint256 _periodFinish
    ) {
        treasuryAddress = _treasuryAddress;
        stakingToken = IERC20Min(_stakingToken);
        rewardsToken = IERC20Min(_rewardsToken);
        rewardRate = _rewardRate;
        periodFinish = _periodFinish;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (((lastTimeRewardApplicable() - lastUpdateTime) *
                rewardRate *
                1e18) / _totalSupply);
    }

    function earned(address account) public view returns (uint256) {
        return
            ((_balances[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) +
            rewards[account];
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();

        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }

        _;
    }

    function stake(uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, "cannot stake 0");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        _totalSupply += _amount;
        _balances[msg.sender] += _amount;
        emit Staked(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, "cannot withdraw 0");
        _totalSupply -= _amount;
        _balances[msg.sender] -= _amount;
        stakingToken.transfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount);
    }

    function getReward() external updateReward(msg.sender) returns (uint256) {
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        rewardsToken.transferFrom(treasuryAddress, msg.sender, reward);
        emit RewardPaid(msg.sender, reward);
        return reward;
    }

    function setRewardRate(uint256 _rewardRate)
        external
        updateReward(address(0))
        onlyOwner
    {
        rewardRate = _rewardRate;
        emit RewardRateSet(rewardRate);
    }

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardRateSet(uint256 rewardRate);
}
