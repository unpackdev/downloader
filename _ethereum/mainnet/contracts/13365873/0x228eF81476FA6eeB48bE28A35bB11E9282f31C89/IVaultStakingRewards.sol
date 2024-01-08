pragma solidity ^0.6.0;

interface IVaultStakingRewards {
    function notifyRewardAmount(address _rewardToken, uint256 _reward) external;
}
