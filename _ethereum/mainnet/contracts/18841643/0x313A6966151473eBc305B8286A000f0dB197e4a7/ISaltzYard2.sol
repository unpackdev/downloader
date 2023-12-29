// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
interface ISaltzYard2 {
    
    function lastTimeRewardApplicable() external view returns (uint);

    function rewardPerToken() external view returns (uint);

    function stake(uint _amount) external;

    function stakeWithLock(uint _amount, uint256 lockinPeriod) external;

    function extendLockin(uint256 extendedTime) external;
    
    function withdraw(uint _amount) external;

    function withdrawForLockedStackers() external;

    function earned(address _account) external view returns (uint);

    function getReward() external;
    
    function setRewardsDuration(uint _duration) external;

    function notifyRewardAmount( uint _amount ) external;

}