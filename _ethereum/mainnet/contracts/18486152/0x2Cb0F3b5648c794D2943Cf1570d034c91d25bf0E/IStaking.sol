// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IStaking {
    event Stake(address indexed _staker, uint indexed _amount, uint _timestamp);
    event Unstake(address indexed _staker, uint indexed amount, uint indexed _rewards, uint _timestamp);
    event UpdatedRewardsPercentage(uint indexed _percentage);

    function stake(uint _amount) external;
    function unstake() external;
    function unstakeForced() external;
    function unstakeSingle(uint _index) external;
    function addRewards(uint _amount) external;
    function computeRewards(address _stakers) external returns (uint);
    function computeRewardsSingle(address _staker, uint _index) external returns (uint);
    function previewUnstake(address _staker, bool _unstakeAll) external returns (uint, uint) ;
}