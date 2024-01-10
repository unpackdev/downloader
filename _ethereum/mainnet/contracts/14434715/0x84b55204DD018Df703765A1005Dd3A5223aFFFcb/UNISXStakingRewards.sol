// SPDX-License-Identifier: MIT

// Based on https://github.com/Synthetixio/synthetix/blob/master/contracts/StakingRewards.sol

pragma solidity ^0.8;

import "./Ownable.sol";
import "./IERC20Min.sol";
import "./ITokenManagerMin.sol";

contract UNISXStakingRewards is Ownable {
    IERC20Min public immutable UNISXToken;
    ITokenManagerMin public immutable xUNISXTokenManager;

    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(
        address _UNISXToken,
        address _tokenManager,
        uint256 _rewardRate
    ) {
        UNISXToken = IERC20Min(_UNISXToken);
        xUNISXTokenManager = ITokenManagerMin(_tokenManager);
        rewardRate = _rewardRate;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (((block.timestamp - lastUpdateTime) * rewardRate * 1e18) /
                _totalSupply);
    }

    function earned(address account) public view returns (uint256) {
        return
            ((_balances[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) +
            rewards[account];
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;

        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }

        _;
    }

    function stake(uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, "cannot stake 0");
        _totalSupply += _amount;
        _balances[msg.sender] += _amount;
        UNISXToken.transferFrom(msg.sender, address(this), _amount);
        xUNISXTokenManager.mint(msg.sender, _amount);
        emit Staked(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, "cannot withdraw 0");
        _totalSupply -= _amount;
        _balances[msg.sender] -= _amount;
        xUNISXTokenManager.burn(msg.sender, _amount);
        UNISXToken.transfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount);
    }

    function getReward() external updateReward(msg.sender) returns (uint256) {
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        UNISXToken.transfer(msg.sender, reward);
        require(
            UNISXToken.balanceOf(address(this)) >= _totalSupply,
            "out of reward"
        );
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
