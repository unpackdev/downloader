pragma solidity 0.4.24;

interface YearnRewardsI {
    function starttime() external returns (uint256);
    function totalRewards() external returns (uint256);
}
