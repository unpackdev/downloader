pragma solidity 0.8.16;
//SPDX-License-Identifier: None

interface IWarlordStaker {

    function getUserAccruedRewards(address reward, address user) external view returns (uint256);

    function stake(uint256 amount, address receiver) external returns (uint256);
    function unstake(uint256 amount, address receiver) external returns (uint256);

    function claimRewards(address reward, address receiver) external returns (uint256);

    function updateRewardState(address reward) external;

}