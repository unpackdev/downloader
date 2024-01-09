//SPDX-License-Identifier: MIT

import "./IERC20.sol";
import "./Ownable.sol";

pragma solidity 0.8.4;

contract PathLPStaking is Ownable{
    IERC20 public stakingToken;
    IERC20 public rewardToken;

    uint public rewardRate = 0;
    uint public rewardsDuration = 365 days;
    uint public startRewardsTime;
    uint public lastUpdateTime;
    uint public lastRewardTimestamp;
    uint public rewardPerTokenStored;

    // total staked
    uint private stakedSupply = 0;
    uint private claimedRewards = 0;

    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;
    mapping(address => uint) private _balances;

    event Staked(address indexed user, uint amountStaked);
    event Withdrawn(address indexed user, uint amountWithdrawn);
    event RewardsClaimed(address indexed user, uint rewardsClaimed);
    event RewardAmountSet(uint rewardRate, uint duration);
    event Recovered(address tokenAddress, uint tokenAmount);

    constructor(address  _stakingTokenAddress, address _rewardTokenAddress, uint _startRewards) {
        stakingToken = IERC20(_stakingTokenAddress);
        rewardToken = IERC20(_rewardTokenAddress);
        startRewardsTime = _startRewards;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = rewardTimestamp();
        if (account != address(0)){
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    //function to check if staking rewards have ended
    function rewardTimestamp() internal view returns (uint) {
        if (block.timestamp < lastRewardTimestamp) {
            return block.timestamp;
        }
        else {
            return lastRewardTimestamp;
        }
    }

    //function to check if staking rewards have started
    function startTimestamp() internal view returns (uint) {
        if (startRewardsTime > lastUpdateTime) {
            return startRewardsTime;
        }
        else {
            return lastUpdateTime;
        }
    }

    function balanceOf(address account) external view returns (uint) {
        return _balances[account];
    }


    function totalStaked() public view returns (uint) {
        return stakedSupply;
    }

    function totalClaimed() public view returns (uint) {
        return claimedRewards;
    }

    function rewardPerToken() public view returns (uint) {
        if (stakedSupply == 0 || block.timestamp < startRewardsTime) {
            return 0;
        }
        return rewardPerTokenStored + (
            (rewardRate * (rewardTimestamp()- startTimestamp()) * 1e18 / stakedSupply)
        );
    }

    function earned(address account) public view returns (uint) {
        return (
            _balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e18
        ) + rewards[account];
    }

    function stake(uint _amount) external updateReward(msg.sender) {
        require(_amount > 0, "Must stake > 0 tokens");
        stakedSupply += _amount;
        _balances[msg.sender] += _amount;
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
        emit Staked(msg.sender, _amount);
    }

    function withdraw(uint _amount) public updateReward(msg.sender) {
        require(_amount > 0, "Must withdraw > 0 tokens");
        stakedSupply -= _amount;
        _balances[msg.sender] -= _amount;
        require(stakingToken.transfer(msg.sender, _amount), "Token transfer failed");
        emit Withdrawn(msg.sender, _amount);
    }

    function getReward() public updateReward(msg.sender) {
        uint reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            claimedRewards += reward;
            require(rewardToken.transfer(msg.sender, reward), "Token transfer failed");
            emit RewardsClaimed(msg.sender, reward);
        }
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    //owner only functions

    function setRewardAmount(uint reward, uint _rewardsDuration) onlyOwner external updateReward(address(0)) {
        rewardsDuration = _rewardsDuration;
        rewardRate = reward / rewardsDuration;
        uint balance = rewardToken.balanceOf(address(this));

        require(rewardRate <= balance / rewardsDuration, "Contract does not have enough tokens for current reward rate");

        lastUpdateTime = block.timestamp;
        if (block.timestamp < startRewardsTime) {
            lastRewardTimestamp = startRewardsTime + rewardsDuration;
        }
        else {
            lastRewardTimestamp = block.timestamp + rewardsDuration;
        }
        emit RewardAmountSet(rewardRate, _rewardsDuration);
    }

    // support recovering rewards
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(stakingToken), "Cannot withdraw the staking token");
        require(IERC20(tokenAddress).transfer(msg.sender, tokenAmount), "transfer failed");
        emit Recovered(tokenAddress, tokenAmount);
    }
}
