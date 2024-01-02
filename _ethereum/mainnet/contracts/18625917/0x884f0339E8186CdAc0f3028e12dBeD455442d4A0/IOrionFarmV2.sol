// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface IOrionFarmV2
{
    //Action
    function create_lock_period(address pool, uint256 amount, uint256 lock_period) external;
    function increase_amount(address pool, uint256 amount) external;
    function increase_lock_period(address pool, uint256 new_lock_period) external;
    function withdraw(address pool) external;
    function claimReward(address pool) external;

    function createSmartReward(address pool) external;

    //View
    function getReward(address pool, address account) external view returns (uint256);
    function getBoost(address pool, address account) external view returns (uint256);
    function getStake(address pool, address account) external view returns (uint256);
    function allStake(address pool) external view returns (uint256);
    function lockTimeStart(address pool, address account) external view returns (uint48);
    function lockTimePeriod(address pool, address account) external view returns (uint48);

    function libStakingReward() external view returns(address);
}

