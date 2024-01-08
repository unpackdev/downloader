// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

interface IPoolRewards {
    /// Emitted after reward added
    event RewardAdded(uint256 reward);
    /// Emitted whenever any user claim rewards
    event RewardPaid(address indexed user, uint256 reward);

    function claimReward(address) external;

    function notifyRewardAmount(uint256 rewardAmount, uint256 endTime) external;

    function updateReward(address) external;

    function claimable(address) external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardForDuration() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);
}
