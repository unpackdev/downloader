// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

interface IRewardPool {
    // View
    function share(uint256 yangId) external view returns (uint256);

    function totalShares() external view returns (uint256);

    // Mutation
    function getReward() external;

    function earned(uint256 yangId) external view returns (uint256);

    function reload(address account) external;

    /// Event
    event RewardAdded(uint256 reward);
    event RewardUpdated(uint256 yangId, uint256 shares, uint256 totalShares);
    event RewardPaid(address account, uint256 reward);
    event RewardRateUpdated(uint256 oldRate, uint256 newRate);
    event RewardReloadAccount(address account);
    event RewardBoostTokenUpdate(address o, address n);
    event PeriodFinishUpdated(uint256 o, uint256 n);
    event TotalRewardUpdated(uint256 o, uint256 n);
    event RewardPoolNotStart(address, uint256, uint256);
}
