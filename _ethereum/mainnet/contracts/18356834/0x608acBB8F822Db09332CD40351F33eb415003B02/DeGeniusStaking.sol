/**
****************************************************
*********** INTERACT WITH THIS CONTRACT ************ 
***************** FROM TELEGRAM AT ***************** 
********* "https://t.me/DegeniusStakingBot" ********
****************************************************


* DeGenius Staking Smart Contract
 *
 * Features:
 * - Staking tokens with duration-based early withdrawal penalties.
 * - Claiming rewards with duration-based reward claim penalties.

 * - Penalties are as follows:
 *   - 0-1 week: 30% penalty
 *   - 1-2 weeks: 15% penalty
 *   - 2-3 weeks: 7.5% penalty
 *   - More than 3 weeks: No penalty
  ______________________________________________________________
 |***Voted on by community "https://t.me/c/1924245293/44567".***|
  --------------------------------------------------------------
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract DeGeniusStakingBot {
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardsToken;
    address public owner;
    address public penaltyRecipient;
    bool public paused;
    uint256 public duration;
    uint256 public finishAt;
    uint256 public updatedAt;
    uint256 public rewardRate;
    uint256 public rewardPerTokenStored;
    uint256 public totalSupply;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public userWeightedDepositTime;
    mapping(address => uint256) public userTotalDeposited;

    error AmountZero();
    error NothingToClaim();
    error RewardsNotFinished();
    error InsufficientBalance();
    error RewardRateZero();
    error Paused();

    event Stake(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event Compound(address indexed user, uint256 amount);
    
    constructor(address _stakingToken, address _rewardToken) {
        owner = msg.sender;
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardToken);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();
        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return _min(finishAt, block.timestamp);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            totalSupply;
    }

    function stake(uint256 _amount) external updateReward(msg.sender) {
        if(paused) revert Paused();
        if(_amount == 0) revert AmountZero();
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        uint256 previousDepositAmount = userTotalDeposited[msg.sender];
        uint256 newTotalDeposit = previousDepositAmount + _amount;
        userWeightedDepositTime[msg.sender] = 
            ((userWeightedDepositTime[msg.sender] * previousDepositAmount) + (block.timestamp * _amount)) / newTotalDeposit;
        userTotalDeposited[msg.sender] = newTotalDeposit;
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
        emit Stake(msg.sender, _amount);
    }


    function withdraw(uint256 _amount) external updateReward(msg.sender) {
        if(paused) revert Paused();
        if(_amount == 0) revert AmountZero();
        uint256 penalty = calculatePenalty(msg.sender, _amount);
        uint256 amountAfterPenalty = _amount - penalty;
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        stakingToken.transfer(msg.sender, amountAfterPenalty);
        if(penalty > 0) {
            uint256 recipientPenalty = (penalty * 30) / 100; // 30% of the penalty
            stakingToken.transfer(penaltyRecipient, recipientPenalty);
        }
        emit Withdraw(msg.sender, amountAfterPenalty);
    }


    function compound() external updateReward(msg.sender) {
        if(paused) revert Paused();
        uint256 amount = rewards[msg.sender];
        if (amount == 0) revert NothingToClaim();
        rewards[msg.sender] = 0;
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Compound(msg.sender, amount);
    }

    function earned(address _account) public view returns (uint256) {
        return
            ((balanceOf[_account] *
                (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18) +
            rewards[_account];
    }

    function claimReward() external updateReward(msg.sender) {
        if(paused) revert Paused();
        uint256 reward = rewards[msg.sender];
        if (reward == 0) revert NothingToClaim();

        uint256 penalty = calculateRewardClaimPenalty(msg.sender, reward);
        uint256 rewardAfterPenalty = reward - penalty;

        rewards[msg.sender] = 0;
        rewardsToken.transfer(msg.sender, rewardAfterPenalty);

        if(penalty > 0) {
            uint256 recipientPenalty = (penalty * 30) / 100;
            rewardsToken.transfer(penaltyRecipient, recipientPenalty);
        }

        emit RewardClaimed(msg.sender, rewardAfterPenalty);
    }


    function setRewardsDuration(uint256 _duration) external onlyOwner {
        if(finishAt >= block.timestamp) revert RewardsNotFinished();
        duration = _duration;
    }

    function notifyRewardAmount(uint256 _amount) external onlyOwner updateReward(address(0)) {
        if (block.timestamp >= finishAt) {
            rewardRate = _amount / duration;
        } else {
            uint256 remainingRewards = (finishAt - block.timestamp) * rewardRate;
            rewardRate = (_amount + remainingRewards) / duration;
        }
        if(rewardRate == 0) revert RewardRateZero();
        if(rewardRate * duration > rewardsToken.balanceOf(address(this))) revert InsufficientBalance();
        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    function setPenaltyRecipient(address _penaltyRecipient) external onlyOwner {
        penaltyRecipient = _penaltyRecipient;
    }

    receive() external payable {
        revert("Contract does not accept Ether directly");
    }

    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }

    
    function calculatePenalty(address _user, uint256 _amount) internal view returns (uint256) {
        uint256 stakedDuration = block.timestamp - userWeightedDepositTime[_user];
        
        // Define the time limits in seconds for 1, 2, and 3 weeks
        uint256 oneWeek = 604800; // seconds in one week
        uint256 twoWeeks = 1209600; // seconds in two weeks
        uint256 threeWeeks = 1814400; // seconds in three weeks

        if (stakedDuration >= threeWeeks) {
            return 0; // No penalty after 3 weeks
        } else if (stakedDuration >= twoWeeks) {
            return (_amount * 75) / 1000; // 7.5% penalty
        } else if (stakedDuration >= oneWeek) {
            return (_amount * 15) / 100; // 15% penalty
        } else {
            return (_amount * 30) / 100; // 30% penalty for less than 1 week
        }
    }

    function calculateRewardClaimPenalty(address _user, uint256 _reward) internal view returns (uint256) {
        uint256 stakedDuration = block.timestamp - userWeightedDepositTime[_user];

        // Define the time limits in seconds for 1, 2, and 3 weeks
        uint256 oneWeek = 604800; // seconds in one week
        uint256 twoWeeks = 1209600; // seconds in two weeks
        uint256 threeWeeks = 1814400; // seconds in three weeks

        if (stakedDuration >= threeWeeks) {
            return 0; // No penalty after 3 weeks
        } else if (stakedDuration >= twoWeeks) {
            return (_reward * 75) / 1000; // 7.5% penalty
        } else if (stakedDuration >= oneWeek) {
            return (_reward * 15) / 100; // 15% penalty
        } else {
            return (_reward * 30) / 100; // 30% penalty for less than 1 week
        }
    }

    
}
