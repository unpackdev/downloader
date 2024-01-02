// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "./IERC20.sol";

import "./IPrimexDNS.sol";
import "./ITraderBalanceVault.sol";
import "./IWhiteBlackList.sol";
import "./ILiquidityMiningRewardDistributorStorage.sol";
import "./IPausable.sol";

interface ILiquidityMiningRewardDistributor is ILiquidityMiningRewardDistributorStorage, IPausable {
    struct RewardsInPMX {
        uint256 minReward;
        uint256 maxReward;
        uint256 extraReward;
    }

    /**
     * @notice Emitted when a reward is claimed by a receiver from a specific bucket.
     * @param receiver The address of the receiver.
     * @param bucket The address of the bucket from which the reward is claimed.
     * @param amount The amount of the claimed reward.
     */
    event ClaimedReward(address indexed receiver, address indexed bucket, uint256 amount);
    /**
     * @notice Emitted when PMX tokens are withdrawn by an admin.
     * @param amount The amount of PMX tokens withdrawn.
     */
    event WithdrawPmxByAdmin(uint256 indexed amount);

    /**
     * @notice Initializes the contract with the specified parameters.
     * @param _primexDNS The address of the IPrimexDNS contract.
     * @param _pmx The address of the PMX token contract.
     * @param _traderBalanceVault The address of the TraderBalanceVault contract.
     * @param _registry The address of the registry contract.
     * @param _treasury The address of the treasury contract.
     * @param _reinvestmentRate The rate at which rewards are reinvested.
     * @param _reinvestmentDuration The duration for which rewards are reinvested.
     * @param _whiteBlackList The address of the WhiteBlackList contract.
     */
    function initialize(
        IPrimexDNS _primexDNS,
        IERC20 _pmx,
        ITraderBalanceVault _traderBalanceVault,
        address _registry,
        address _treasury,
        uint256 _reinvestmentRate,
        uint256 _reinvestmentDuration,
        IWhiteBlackList _whiteBlackList
    ) external;

    /**
     * @notice Updates the reward amount for a specific bucket.
     * @dev Only callable by the PrimexDNS contract.
     * @param _bucketName The name of the bucket.
     * @param _pmxRewardsAmount The amount of PMX rewards to be allocated to the bucket.
     */
    function updateBucketReward(string memory _bucketName, uint256 _pmxRewardsAmount) external;

    /**
     * @notice Adds points for a user for future reward distribution.
     * @dev Only callable by the Bucket contract.
     * @param _bucketName The name of the bucket.
     * @param _user The address of the user.
     * @param _miningAmount The amount of mining points to be added.
     * @param _maxStabilizationPeriodEnd The maximum end timestamp of the stabilization period.
     * @param _maxPeriodTime The maximum period time.
     * @param _currentTimestamp The current timestamp.
     */
    function addPoints(
        string memory _bucketName,
        address _user,
        uint256 _miningAmount,
        uint256 _maxStabilizationPeriodEnd,
        uint256 _maxPeriodTime,
        uint256 _currentTimestamp
    ) external;

    /**
     * @notice Removes points for a user.
     * @dev Only callable by the Bucket contract.
     * @param _name The name of the bucket.
     * @param _user The address of the user.
     * @param _amount The amount of mining points to be removed.
     */
    function removePoints(string memory _name, address _user, uint256 _amount) external;

    /**
     * @notice Claims the accumulated rewards for a specific bucket.
     * @param _bucketName The name of the bucket.
     */
    function claimReward(string memory _bucketName) external;

    /**
     * @notice Moves rewards from one bucket to another.
     * @dev Only callable by the Bucket contract.
     * @param _bucketFrom The name of the source bucket.
     * @param _bucketTo The name of the destination bucket.
     * @param _user The address of the user.
     * @param _isBucketLaunched A flag indicating if the destination bucket is launched.
     * @param _liquidityMiningDeadline The deadline for liquidity mining
     */
    function reinvest(
        string memory _bucketFrom,
        string memory _bucketTo,
        address _user,
        bool _isBucketLaunched,
        uint256 _liquidityMiningDeadline
    ) external;

    /**
     * @dev The function to withdraw PMX from a delisted bucket or a bucket where liquidity mining failed (after reinvesting period).
     * Emits WithdrawPmxByAdmin event.
     * @param _bucketFrom Name of the bucket with failed liquidity mining event.
     */
    function withdrawPmxByAdmin(string memory _bucketFrom) external;

    /**
     * @notice Retrieves information about a lender in a specific bucket.
     * @param _bucketName The name of the bucket.
     * @param _lender The address of the lender.
     * @param _timestamp The timestamp for which the information is queried.
     * @return amountInMining The amount of tokens the lender has in mining for the given bucket.
     * @return currentPercent The current percentage of rewards the lender is eligible to receive for the given bucket.
     * Measured in WAD (1 WAD = 100%).
     * @return rewardsInPMX An object containing information about the lender's rewards in PMX for the given bucket.
     */
    function getLenderInfo(
        string calldata _bucketName,
        address _lender,
        uint256 _timestamp
    ) external view returns (uint256 amountInMining, uint256 currentPercent, RewardsInPMX memory rewardsInPMX);

    /**
     * @notice Retrieves rewards information about a specific bucket.
     * @param _bucketName The name of the bucket.
     * @return totalPmxReward The total amount of PMX reward in the bucket.
     * @return withdrawnRewards The total amount of withdrawn rewards from the bucket.
     * @return totalPoints The total number of mining points in the bucket.
     */
    function getBucketInfo(
        string calldata _bucketName
    ) external view returns (uint256 totalPmxReward, uint256 withdrawnRewards, uint256 totalPoints);

    /**
     * @notice Retrieves the amount of tokens a lender has in mining for a specific bucket.
     * @param _bucket The name of the bucket.
     * @param _lender The address of the lender.
     * @return The amount of tokens the lender has in mining for the given bucket.
     */
    function getLenderAmountInMining(string calldata _bucket, address _lender) external view returns (uint256);
}
