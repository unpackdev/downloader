pragma solidity 0.6.12;

interface IRewardable {
    function addRewards(address rewardToken, uint256 amount) external;
}
