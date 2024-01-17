// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

import "./ITokenikV1StakingRNIK.sol";
import "./ITokenikV1Rewards.sol";

contract TokenikV1StakingRNIK is ITokenikV1StakingRNIK {
    
    struct stake{
        uint256 amount;
        uint256 startDate;
    }
    
    address public override rewards; //rewards contract
    uint256 public override stakingApy; //staking apy 2 decimals
    address public override apySetter; //address of the apy setter
    uint256 public override minStakeDuration; //minimum stake duration (3888000 - 45 days)
    bool public override stakingOpen; //pause new stakes
    uint256 public override stakingCloseDate; //staking deadline
    uint256 public override totalStaked; // total RNIK staked

    mapping(address => stake) public userStakes;

    modifier onlySetter() {
        require(msg.sender == apySetter, 'TokenikV1: Forbidden');
        _;
    }
    
    constructor() {
        apySetter = msg.sender;
        stakingApy = 2000; //20%
        minStakeDuration = 3888000; // 45 days
    }


    function stakeRNIK(uint256 _amount) external override{
        require(stakingOpen, 'TokenikV1: Staking is disabled');
        require(_amount > 0, 'TokenikV1: Invalid amount');

        bool useRewards = ITokenikV1Rewards(rewards).removeReward(msg.sender, _amount);
        require(useRewards, 'TokenikV1: Incorrect amount');
        
        uint256 pendingInterest = getInterestInternal(msg.sender);
        uint256 addAmount = pendingInterest + _amount;
        userStakes[msg.sender].amount += addAmount;
        userStakes[msg.sender].startDate = block.timestamp;
        totalStaked += addAmount;

        emit StakeRNIK(msg.sender, _amount);
        
    }

    function unstakeRNIK() external override{
        
        require(block.timestamp >= (userStakes[msg.sender].startDate + minStakeDuration), 'TokenikV1: cannot unstake early');
        require(userStakes[msg.sender].amount > 0,'TokenikV1: nothing to unstake');

        uint256 earnedInterest = getInterestInternal(msg.sender);

        uint256 totalAmount = userStakes[msg.sender].amount + earnedInterest;
        totalStaked = totalStaked - userStakes[msg.sender].amount;
        userStakes[msg.sender].amount = 0;

        ITokenikV1Rewards(rewards).addReward(msg.sender, totalAmount);

        emit UnstakeRNIK(msg.sender, totalAmount);
    }

    function getInterestInternal(address _account) internal view returns(uint256){
        
        uint256 lastDay = block.timestamp;

        if(stakingCloseDate !=0 ){
            if(block.timestamp > stakingCloseDate){
                lastDay = stakingCloseDate;
            }
        }

        uint256 daysStaked = (lastDay - userStakes[_account].startDate) / 86400;

        if(daysStaked == 0) return(0);

        uint256 interestEarned = userStakes[_account].amount * stakingApy * daysStaked / 3650000;

        return interestEarned;
    }

    function getInterest(address _account) external view override returns(uint256){
        
        return getInterestInternal(_account);
    }

    function getUserStake(address _account) external view override returns(uint256, uint256) {
 
        return (userStakes[_account].amount, userStakes[_account].startDate);
    }
    
    function setRewardsAddress(address _address) external override onlySetter {
        require(_address != address(0), 'TokenikV1: cannot set empty address');
        rewards = _address;
    }

    function setApySetter(address _address) external override onlySetter {
        require(_address != address(0), 'TokenikV1: cannot set empty address');
        apySetter = _address;
    }

    function setStakingApy(uint256 _stakingApy) external override onlySetter {
        require(_stakingApy > stakingApy,'TokenikV1: APY can only be increased');
        stakingApy = _stakingApy;
    }

    function setMinStakeDuration(uint256 _minStakeDuration) external override onlySetter {
        minStakeDuration = _minStakeDuration;
    }

    function setStakingOpen(bool _stakingOpen) external override onlySetter {
        stakingOpen = _stakingOpen;
    }

    function setStakingCloseDate(uint256 _stakingCloseDate) external override onlySetter {
        stakingCloseDate = _stakingCloseDate;
    }

}