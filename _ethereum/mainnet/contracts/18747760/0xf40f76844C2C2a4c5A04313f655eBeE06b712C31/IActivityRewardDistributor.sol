// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "./IActivityRewardDistributorStorage.sol";
import "./IWhiteBlackList.sol";
import "./IBucket.sol";
import "./IPausable.sol";

interface IActivityRewardDistributor is IActivityRewardDistributorStorage, IPausable {
    enum Role {
        LENDER,
        TRADER
    }

    struct BucketWithRole {
        address bucketAddress;
        Role role;
    }

    /**
     * @notice Emitted on claimReward()
     * @param user The address of the user who claimed reward
     * @param bucket The address of the bucket this reward is related to
     * @param role User role - TRADER or LENDER
     * @param amount Claimed amount
     */
    event ClaimReward(address indexed user, address indexed bucket, Role indexed role, uint256 amount);

    /**
     * @notice  Initializes the ActivityRewardDistributor contract.
     * @dev This function should only be called once during the initial setup of the contract.
     * @param _pmx The address of the PMXToken contract.
     * @param _dns The address of the PrimexDNS contract.
     * @param _registry The address of the PrimexRegistry contract.
     * @param _treasury The address of the treasury where fees will be collected.
     * @param _traderBalanceVault The address of the TraderBalanceVault contract.
     * @param _whiteBlackList The address of the WhiteBlackList contract.
     */
    function initialize(
        IERC20 _pmx,
        IPrimexDNS _dns,
        address _registry,
        address _treasury,
        ITraderBalanceVault _traderBalanceVault,
        IWhiteBlackList _whiteBlackList
    ) external;

    /**
     * @notice  Saves user activity in the protocol for reward calculation
     * @param   bucket  The address of the bucket
     * @param   user  User address
     * @param   newBalance  User balance after action
     * @param   role  User role - TRADER or LENDER
     */
    function updateUserActivity(IBucket bucket, address user, uint256 newBalance, Role role) external;

    /**
     * @notice  Saves activity of multiple users in the protocol for reward calculation
     * @param   bucket  The address of the bucket
     * @param   users  Array of user addresses
     * @param   newBalances  Array of users balances after action
     * @param   length  The length of the users and oldBalances arrays
     * @param   role  User role - TRADER or LENDER
     */
    function updateUsersActivities(
        IBucket bucket,
        address[] calldata users,
        uint256[] calldata newBalances,
        uint256 length,
        Role role
    ) external;

    /**
     * @notice Allows the caller to claim their accumulated reward from the specified buckets.
     * @param bucketsArray The array of BucketWithRole objects containing the buckets from which to claim the rewards.
     */
    function claimReward(BucketWithRole[] calldata bucketsArray) external;

    /**
     * @notice Sets up activity rewards distribution in bucket with the specified role and reward parameters.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param bucket The address of the bucket to set up.
     * @param role The role associated with the bucket.
     * @param increaseAmount The amount by which to increase the total reward for the bucket (in PMX).
     * Adds specified amount to totalReward of the bucket. Initial value of totalReward is 0.
     * @param rewardPerDay The reward amount per day for the bucket.
     */
    function setupBucket(address bucket, Role role, uint256 increaseAmount, uint256 rewardPerDay) external;

    /**
     * @notice Allows the caller to withdraw PMX tokens from a specific bucket.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param bucket The address of the bucket from which to withdraw PMX tokens.
     * @param role The role associated with the bucket.
     * @param amount The amount of PMX tokens to withdraw.
     */
    function withdrawPmx(address bucket, Role role, uint256 amount) external;

    /**
     * @notice Decreases the reward per day for a bucket and role.
     * @dev Only callable by the EMERGENCY_ADMIN role.
     * @param bucket The address of the bucket for which to decrease the reward per day.
     * @param role The role associated with the bucket.
     * @param rewardPerDay The amount by which to decrease the reward per day.
     */
    function decreaseRewardPerDay(address bucket, Role role, uint256 rewardPerDay) external;

    /**
     * @notice Returns the accumulated reward for a specific bucket and role.
     * @param bucket The address of the bucket for which to retrieve the accumulated reward.
     * @param role The role associated with the bucket.
     * @return The accumulated reward for the specified bucket and role.
     */
    function getBucketAccumulatedReward(address bucket, Role role) external view returns (uint256);

    /**
     * @notice Returns the claimable reward for a user across multiple buckets.
     * @param bucketsArray The array of BucketWithRole objects containing the buckets to check for claimable rewards.
     * @param user The address of the user for whom to calculate the claimable reward.
     * @return The total claimable reward for the specified user across all provided buckets.
     */
    function getClaimableReward(BucketWithRole[] calldata bucketsArray, address user) external view returns (uint256);

    /**
     * @notice Retrieves the user information from a specific bucket and role.
     * @param bucket The address of the bucket from which to retrieve the user information.
     * @param role The role associated with the bucket.
     * @param user The address of the user for whom to retrieve the information.
     * @return A UserInfo struct containing the user information.
     */
    function getUserInfoFromBucket(address bucket, Role role, address user) external view returns (UserInfo memory);
}
