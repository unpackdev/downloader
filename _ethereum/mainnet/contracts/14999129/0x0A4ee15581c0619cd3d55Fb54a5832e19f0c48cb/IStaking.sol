// SPDX-License-Identifier: AGPL-3.0-only
// ERC20 Extensions v1.1.1
pragma solidity ^0.8.0;

/// @title Staking contract for ERC20 tokens
/// @author Daniel Gretzke
/// @notice Allows users to stake an underlying ERC20 token and receive a new ERC20 token in return which tracks their stake in the pool
/// @notice Rewards in form of the underlying ERC20 token are distributed proportionally across all staking participants
/// @notice Rewards in ETH are distributed proportionally across all staking participants
interface IStaking {
    event RewardsReceived(address indexed from, uint256 amount);
    event Deposit(address indexed user, uint256 underlyingToken, uint256 overlyingToken);
    event Withdraw(address indexed user, uint256 underlyingToken, uint256 overlyingToken);
    event RewardClaimed(address indexed user, address indexed to, uint256 amount);

    function claimedRewards(address account) external view returns (uint256 claimedRewards);

    /// @notice allows to deposit the underlying token into the staking contract
    /// @dev mints an amount of overlying tokens according to the stake in the pool
    /// @param amount amount of underlying token to deposit
    /// @return amount of overlying tokens received
    function deposit(uint256 amount) external returns (uint256);

    /// @notice allows to withdraw the underlying token from the staking contract
    /// @param amount of overlying tokens to withdraw
    /// @param claim whether or not to claim ETH rewards
    /// @return amount of underlying tokens withdrawn
    function withdraw(uint256 amount, bool claim) external returns (uint256);

    /// @notice allows to claim accumulated ETH rewards
    /// @param to address to send rewards to
    /// @return amount of rewards claimed
    function claimRewards(address to) external returns (uint256);

    /// @return accumulated underlying token balance that can be withdrawn by the user
    function tokenBalance(address user) external view returns (uint256);

    /// @return total amount of ETH rewards earned by user
    function totalRewardsEarned(address user) external view returns (uint256);

    /// @return amount of ETH rewards that can be claimed by user
    function claimableRewardsOf(address user) external view returns (uint256);
}
