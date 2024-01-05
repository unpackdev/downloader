/*
__/\\\________/\\\_____/\\\\\\\\\\\____/\\\\\\\\\\\\\\\________/\\\\\\\\\_        
 _\///\\\____/\\\/____/\\\/////////\\\_\/\\\///////////______/\\\////////__       
  ___\///\\\/\\\/_____\//\\\______\///__\/\\\_______________/\\\/___________      
   _____\///\\\/________\////\\\_________\/\\\\\\\\\\\______/\\\_____________     
    _______\/\\\____________\////\\\______\/\\\///////______\/\\\_____________    
     _______\/\\\_______________\////\\\___\/\\\_____________\//\\\____________   
      _______\/\\\________/\\\______\//\\\__\/\\\______________\///\\\__________  
       _______\/\\\_______\///\\\\\\\\\\\/___\/\\\\\\\\\\\\\\\____\////\\\\\\\\\_ 
        _______\///__________\///////////_____\///////////////________\/////////__

Visit and follow!

* Website:  https://www.ysec.finance
* Twitter:  https://twitter.com/YearnSecure
* Telegram: https://t.me/YearnSecure
* Medium:   https://yearnsecure.medium.com/

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Staker.sol";
import "./IERC20.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Math.sol";

contract YsecYieldFarm is Context, ReentrancyGuard, Ownable{
    using SafeMath for uint;

    address public _ysecTokenAddress;
    address public _ysecPresaleAddress;
    uint256 public StartDate;
    uint256 public EndDate;
    uint256 public EthAmount;
    uint256 public TotalStaked;
    uint256 public RewardPerTokenStored;
    uint256 public LastUpdateTime;
    uint256 public RewardRate;
    uint256 public TotalClaimedEthAmount;
    uint256 public DepositCount;

    uint256 public periodDuration = 14 days;

    mapping(address => Staker) public Stakers;
    uint256 public TotalStakers;

    event Staked(address forAddress, uint256 amount);
    event Unstaked(address forAddress, uint256 amount);
    event RewardClaimed(address forAddress, uint256 amount);
    event RewardAdded(uint256 reward);

    constructor(address tokenAddress, address ysecPresaleAddress) public{
        _ysecTokenAddress = tokenAddress;
        _ysecPresaleAddress = ysecPresaleAddress;
    }

    receive() DepositCheck() external payable {
        DepositCount = DepositCount.add(1);
        EthAmount = EthAmount.add(msg.value);
        if(StartDate != 0) NotifyRewardAmount(msg.value);
    }

    function Stake(uint256 amount) external nonReentrant() updateReward(_msgSender()){
        require(amount > 0, "Cannot stake 0");
        require(IERC20(_ysecTokenAddress).allowance(_msgSender(), address(this)) >= amount , "Transfer of token has not been approved");
        if(StartDate == 0) 
        {
            StartDate = block.timestamp;
            EndDate = block.timestamp.add(14 days);
            NotifyRewardAmount(EthAmount);
        }
        if(Stakers[_msgSender()].StakedAmount == 0) TotalStakers = TotalStakers.add(1);
        TotalStaked = TotalStaked.add(amount);
        Stakers[_msgSender()].StakedAmount = Stakers[_msgSender()].StakedAmount.add(amount);
        IERC20(_ysecTokenAddress).transferFrom(_msgSender(), address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function Unstake() external nonReentrant() updateReward(_msgSender()){
        require(Stakers[_msgSender()].StakedAmount > 0, "No staking amount found!");

        uint256 stakedAmount = Stakers[_msgSender()].StakedAmount;
        Stakers[_msgSender()].StakedAmount = 0;
        TotalStaked = TotalStaked.sub(stakedAmount);
        TotalStakers = TotalStakers.sub(1);
        IERC20(_ysecTokenAddress).transfer(_msgSender(), stakedAmount);

        InternalClaimReward();
        emit Unstaked(_msgSender(), stakedAmount);
    }

    function ClaimReward() external nonReentrant() updateReward(_msgSender()){
        InternalClaimReward();
    }

    function InternalClaimReward() private updateReward(_msgSender()){
        uint256 reward = Earned(_msgSender());
        if (reward > 0) {
            Stakers[_msgSender()].Reward = 0;
            TotalClaimedEthAmount = TotalClaimedEthAmount.add(reward);
            (bool successReward, ) = msg.sender.call{value: reward}('');
            require(successReward, "Reward transfer failed.");
            emit RewardClaimed(msg.sender, reward);
        }
    }

    modifier updateReward(address account) {
        RewardPerTokenStored = RewardPerToken();
        LastUpdateTime = LastTimeRewardApplicable();
        if (account != address(0)) {
            Stakers[account].Reward = Earned(account);
            Stakers[account].UserRewardPerTokenPaid = RewardPerTokenStored;
        }
        _;
    }

    function RewardPerToken() public view returns (uint256) {
        if (TotalStaked == 0) {
            return RewardPerTokenStored;
        }
        return
            RewardPerTokenStored.add(
                LastTimeRewardApplicable()
                .sub(LastUpdateTime)
                .mul(RewardRate)
                .mul(1e18)
                .div(TotalStaked)
            );
    }

    function LastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, EndDate);
    }

    function Earned(address account) public view returns (uint256) {
        return Stakers[account].StakedAmount.mul(RewardPerToken().sub(Stakers[account].UserRewardPerTokenPaid)).div(1e18)
            .add(Stakers[account].Reward);
    }

    function NotifyRewardAmount(uint256 reward) private updateReward(address(0)){
        uint256 remaining;
        if(block.timestamp >= EndDate) {
            remaining = 0;
        }else{
            remaining = EndDate.sub(block.timestamp);
        }        
        uint256 leftover = remaining.mul(RewardRate);
        if(block.timestamp >= EndDate) EndDate = block.timestamp.add(periodDuration);
        RewardRate = reward.add(leftover).div(EndDate - block.timestamp);
        LastUpdateTime = block.timestamp;
        emit RewardAdded(reward);
    }

    function GetStaker(address forAddress) public view returns(Staker memory){
        return Stakers[forAddress];
    }

    function GetStakedAmount(address forAddress) public view returns(uint256){
        return Stakers[forAddress].StakedAmount;
    }

    modifier DepositCheck(){
        require(_msgSender() == _ysecPresaleAddress || _msgSender() == owner(), "Caller is not allowed to deposit");
        _;
    }
}