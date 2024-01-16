// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IRewards{
    function withdraw(uint256 _amount, bool _claim) external returns(bool);
    function withdrawAll(bool _claim) external;
    function withdrawAndUnwrap(uint256 _amount, bool _claim) external returns(bool);
    function stake(uint256 _amount) external returns(bool);
    function stakeFor(address _account,uint256 _amount) external returns(bool);
    function earned(address) external view returns (uint256);
    function extraRewardsLength() external view returns (uint256);  //already external function
    function extraRewards(uint256) external view returns(address);  //contract address of extra rewards 
    function rewardToken() external view returns(address);
    function getReward(address,bool) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function getReward(bool) external;
    function rewards(address) external view returns (uint256);

}