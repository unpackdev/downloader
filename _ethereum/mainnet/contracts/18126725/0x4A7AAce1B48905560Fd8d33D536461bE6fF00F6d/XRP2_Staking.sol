// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract XRP2_Staking is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Staker {
        uint256 amount;
        uint256 timestamp;
    }

    mapping(address => Staker) public stakers;

    IERC20 public xrp2;

    uint256 public stakingPeriod;
    uint256 public totalStakedAmount;
    uint256 public endTime;
    uint256 public rewardPer = 120;

    constructor(
        IERC20 _xrp2
    ) {
        xrp2 = _xrp2;
    }

    // Set StakingPeriod
    function setStakingPeriod(uint256 _stakingPeriod) external onlyOwner {  
        stakingPeriod = _stakingPeriod;
    }

    // set end time of staking
    function setEndTime(uint256 _endTime) external onlyOwner {  
        endTime = _endTime;
    }

    // set Reward Percent
    function setRewardPer(uint256 _rewardPer) external onlyOwner {  
        rewardPer = _rewardPer;
    }

    // Staking function
    function stake(uint256 _amount) external {
        require(_amount > 0, "Insufficient token balance");
        require(block.timestamp < endTime, "Staking duration is ended");

        // Transfer tokens from user to contract
        // Assuming the token contract is already deployed
        // and the transferFrom function is implemented
        // in the token contract
        // You may need to adjust the function signature and parameters 
        // based on your specific token contract

        xrp2.safeTransferFrom(address(msg.sender), address(this), _amount);

        stakers[msg.sender] = Staker((stakers[msg.sender].amount.add(_amount)), block.timestamp);

        totalStakedAmount = totalStakedAmount.add(_amount);
    }

    // Unstaking function
    function unstake() external {
        Staker storage userStake = stakers[msg.sender];
        require(block.timestamp >= userStake.timestamp.add(stakingPeriod), "Unstaking period not reached");

        uint256 reward = userStake.amount.mul(rewardPer).div(1000);
        uint256 totalAmount = userStake.amount.add(reward);

        // Transfer tokens back to user
        // Assuming the token contract is already deployed
        // and the transfer function is implemented
        // in the token contract
        // You may need to adjust the function signature and parameters 
        // based on your specific token contract
        xrp2.safeTransfer(address(msg.sender), totalAmount);

        totalStakedAmount = totalStakedAmount.sub(userStake.amount);

        delete stakers[msg.sender];
    }

    // Withdraw reward. EMERGENCY ONLY.
    function emergencyRewardWithdraw(uint256 _amount) public onlyOwner {
        require(_amount < xrp2.balanceOf(address(this)), 'not enough token');
        xrp2.safeTransfer(address(msg.sender), _amount);
    }
}