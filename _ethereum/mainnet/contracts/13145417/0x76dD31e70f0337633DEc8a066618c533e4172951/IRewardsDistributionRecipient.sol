pragma solidity ^0.6.0;

interface IRewardsDistributionRecipient {
    function notifyRewardAmount(uint256 reward) external;

    function setStrategyWhoCanAutoStake(address addr, bool flag) external;
}
