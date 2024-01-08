pragma solidity ^0.8.0;

interface HarvestStakePool {

    function balanceOf(address account) external view returns (uint256);

    function getReward() external;

    function stake(uint256 amount) external;

    function rewardPerToken() external view returns (uint256);

    function withdraw(uint256 amount) external;

    function exit() external;
}
