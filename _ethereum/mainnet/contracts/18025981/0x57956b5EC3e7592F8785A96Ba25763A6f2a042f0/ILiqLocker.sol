// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ILiqLocker {
    function lock(address _account, uint256 _amount) external;

    function checkpointEpoch() external;

    function epochCount() external view returns (uint256);

    function balanceAtEpochOf(uint256 _epoch, address _user) external view returns (uint256 amount);

    function totalSupplyAtEpoch(uint256 _epoch) external view returns (uint256 supply);

    function queueNewRewards(address _rewardsToken, uint256 reward) external;

    function getReward(address _account, bool _stake) external;

    function getReward(address _account) external;

    function getRewardFor(address _account) external returns (uint256 rewardAmount);

    function earned(address _account, address token) external view returns (uint256 userRewards);
}
