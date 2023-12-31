// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}

contract HugMEStakingContract  {
    address payable public owner;
    IERC20 public hugMEToken;
    uint256 public minimumStakeAmount = 1e6 * 1e18; // 1 million tokens, assuming 18 decimals
    uint256 public lockPeriod = 6 * 30 days; // representing 6 months
    uint256 public yearlyInterestRate = 6; // 6%

    struct StakeInfo {
        uint256 amount;
        uint256 timestamp;
        uint256 interestRate;
    }

    struct StakeInfoWithPendingTime {
        uint256 amount;
        uint256 timestamp;
        uint256 interestRate;
        uint256 pendingTime;
    }

    mapping(address => StakeInfo[]) public stakingInfo;

    event Staked(address indexed user, uint256 amount, uint256 timestamp);
    event Withdrawn(address indexed user, uint256 amount, uint256 stakeIndex);
    event Restaked(address indexed user, uint256 amount, uint256 stakeIndex);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(IERC20 _hugMEToken) {
        hugMEToken = _hugMEToken;
         owner = payable(msg.sender);
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function setMinimumStakeAmount(uint256 _minimumStakeAmount) external onlyOwner {
        minimumStakeAmount = _minimumStakeAmount;
    }

    function setLockPeriod(uint256 _lockPeriod) external onlyOwner {
        lockPeriod = _lockPeriod;
    }

    function setYearlyInterestRate(uint256 _yearlyInterestRate) external onlyOwner {
        yearlyInterestRate = _yearlyInterestRate;
    }

    function stake(uint256 _amount) external {
        require(_amount >= minimumStakeAmount, "Insufficient staking amount");
        hugMEToken.transferFrom(msg.sender, address(this), _amount);
        stakingInfo[msg.sender].push(StakeInfo(_amount, block.timestamp, yearlyInterestRate));
        emit Staked(msg.sender, _amount, block.timestamp);
    }

    function withdraw(uint256 stakeIndex) external {
        require(stakeIndex < stakingInfo[msg.sender].length, "Invalid stake index");
        require(block.timestamp >= stakingInfo[msg.sender][stakeIndex].timestamp + lockPeriod, "Staking period not yet over");

        uint256 stakingPeriod = block.timestamp - stakingInfo[msg.sender][stakeIndex].timestamp;
        uint256 reward = (stakingInfo[msg.sender][stakeIndex].amount * stakingInfo[msg.sender][stakeIndex].interestRate * stakingPeriod) / (365 days * 100);
        uint256 amountToWithdraw = stakingInfo[msg.sender][stakeIndex].amount + reward;

        // Remove the stake info
        stakingInfo[msg.sender][stakeIndex] = stakingInfo[msg.sender][stakingInfo[msg.sender].length - 1];
        stakingInfo[msg.sender].pop();

        hugMEToken.transfer(msg.sender, amountToWithdraw);
        emit Withdrawn(msg.sender, amountToWithdraw, stakeIndex);
    }

    function restake(uint256 stakeIndex) external {
        require(stakeIndex < stakingInfo[msg.sender].length, "Invalid stake index");
        require(block.timestamp >= stakingInfo[msg.sender][stakeIndex].timestamp + lockPeriod, "Staking period not yet over");

        uint256 stakingPeriod = block.timestamp - stakingInfo[msg.sender][stakeIndex].timestamp;
        uint256 reward = (stakingInfo[msg.sender][stakeIndex].amount * stakingInfo[msg.sender][stakeIndex].interestRate * stakingPeriod) / (365 days * 100);
        uint256 newStakeAmount = stakingInfo[msg.sender][stakeIndex].amount + reward;

        // Update the stake info with new values
        stakingInfo[msg.sender][stakeIndex].amount = newStakeAmount;
        stakingInfo[msg.sender][stakeIndex].timestamp = block.timestamp;
        stakingInfo[msg.sender][stakeIndex].interestRate = yearlyInterestRate;

        emit Restaked(msg.sender, newStakeAmount, stakeIndex);
    }

    function getUserStakes(address user) external view returns (StakeInfoWithPendingTime[] memory) {
        StakeInfoWithPendingTime[] memory stakesWithPendingTime = new StakeInfoWithPendingTime[](stakingInfo[user].length);
        
        for (uint256 i = 0; i < stakingInfo[user].length; i++) {
            uint256 endTimestamp = stakingInfo[user][i].timestamp + lockPeriod;
            uint256 pendingTime = block.timestamp >= endTimestamp ? 0 : endTimestamp - block.timestamp;
            
            stakesWithPendingTime[i] = StakeInfoWithPendingTime({
                amount: stakingInfo[user][i].amount,
                timestamp: stakingInfo[user][i].timestamp,
                interestRate: stakingInfo[user][i].interestRate,
                pendingTime: pendingTime
            });
        }
        
        return stakesWithPendingTime;
    }

    function getStakeInfo(address user, uint256 stakeIndex) external view returns (StakeInfoWithPendingTime memory) {
        require(stakeIndex < stakingInfo[user].length, "Invalid stake index");
        
        uint256 endTimestamp = stakingInfo[user][stakeIndex].timestamp + lockPeriod;
        uint256 pendingTime = block.timestamp >= endTimestamp ? 0 : endTimestamp - block.timestamp;
        
        return StakeInfoWithPendingTime({
            amount: stakingInfo[user][stakeIndex].amount,
            timestamp: stakingInfo[user][stakeIndex].timestamp,
            interestRate: stakingInfo[user][stakeIndex].interestRate,
            pendingTime: pendingTime
        });
    }
     // Transfer ownership
    function transferOwnership(address payable newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}