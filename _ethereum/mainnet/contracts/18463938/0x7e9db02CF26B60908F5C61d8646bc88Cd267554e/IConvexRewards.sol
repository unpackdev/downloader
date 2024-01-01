// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

/// Convex reward contracts interface
interface IConvexRewards {
    /// Get balance of an address
    function balanceOf(address _account) external view returns (uint256);

    /// Withdraw to a convex tokenized deposit
    function withdraw(uint256 _amount, bool _claim) external returns (bool);

    /// Withdraw directly to curve LP token
    function withdrawAndUnwrap(uint256 _amount, bool _claim) external returns (bool);

    /// Claim rewards
    function getReward(address _account, bool _claimExtras) external returns (bool);

    function getReward(address _account, bool _claimExtras, bool _stake) external;

    /// Stake a convex tokenized deposit
    function stake(uint256 _amount) external returns (bool);

    /// Stake a convex tokenized deposit for another address(transfering ownership)
    function stakeFor(address _account, uint256 _amount) external returns (bool);

    /// Used to determine what token is rewarded
    function rewardToken() external view returns (address);

    /// See how much rewards an address will receive if they claim their rewards now.
    function earned(address account) external view returns (uint256);

    function extraRewardsLength() external view returns (uint256);

    function extraRewards(uint256 index) external view returns (address);
}
