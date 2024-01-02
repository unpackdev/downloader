// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface IStaking
{
    //staking
    function getReward(address account) external view returns (uint256);
    function getStake(address account) external view returns (uint256);
    function allStake() external view returns (uint256);
    function rewardRate() external view returns (uint256);
    function rateCumulative() external view returns (uint256);
    function rateTime() external view returns (uint256);


    function getRewardWithdraw(address account) external view returns (uint256);
    function getRewardCumulative(address account) external view returns (uint256);
    function getRewardCumulativeAll() external view returns (uint256);

}