// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "./IERC20Metadata.sol";

import "./ILiquidityMiningRewardDistributor.sol";
import "./IInterestRateStrategy.sol";
import "./IBucket.sol";
import "./IPTokensFactory.sol";
import "./IDebtTokensFactory.sol";

interface IBucketsFactory {
    /**
     * @param nameBucket The name of the new Bucket
     * @param positionManager The address of PositionManager
     * @param assets The list of active assets in bucket
     * @param pairPriceDrops The list of pairPriceDrops for active assets
     * @param underlyingAsset The underlying asset for bucket operations
     * @param feeBuffer The fee buffer of the bucket
     * @param reserveRate The reserve portion of the interest that goes to the Primex reserve
     */
    struct CreateBucketParams {
        string nameBucket;
        address positionManager;
        address priceOracle;
        address dns;
        address reserve;
        address whiteBlackList;
        address[] assets;
        IERC20Metadata underlyingAsset;
        uint256 feeBuffer;
        uint256 withdrawalFeeRate;
        uint256 reserveRate;
        // liquidityMining params
        ILiquidityMiningRewardDistributor liquidityMiningRewardDistributor;
        uint256 liquidityMiningAmount; // if 0 liquidityMining is off
        uint256 liquidityMiningDeadline;
        uint256 stabilizationDuration;
        IInterestRateStrategy interestRateStrategy;
        uint256 maxAmountPerUser;
        bool isReinvestToAaveEnabled;
        uint128 estimatedBar;
        uint128 estimatedLar;
        bytes barCalcParams;
        uint256 maxTotalDeposit;
    }

    event BucketCreated(address bucketAddress);
    event PTokensFactoryChanged(address pTokensFactory);
    event DebtTokensFactoryChanged(address debtTokensFactory);

    function registry() external returns (address);

    /**
     * @notice Creates a new Bucket. Deploys bucket, pToken, debtToken contracts.
     * @dev Only the MEDIUM_TIMELOCK_ADMIN role can call this function.
     * @param _params The parameters for creating the bucket.
     */
    function createBucket(CreateBucketParams memory _params) external;

    /**
     * @notice Set a new pTokens factory contract address.
     * @dev This function can only be called by the DEFAULT_ADMIN_ROLE.
     * @param _pTokensFactory The address of a new pTokens factory contract to set.
     */
    function setPTokensFactory(IPTokensFactory _pTokensFactory) external;

    /**
     * @notice Set a new debtTokens factory contract address.
     * @dev This function can only be called by the DEFAULT_ADMIN_ROLE.
     * @param _debtTokensFactory The address of a new debtTokens factory contract to set.
     */
    function setDebtTokensFactory(IDebtTokensFactory _debtTokensFactory) external;

    /**
     * @dev Returns an array of all deployed bucket addresses.
     * @return list of all deployed buckets
     */
    function allBuckets() external view returns (address[] memory);

    function buckets(uint256) external view returns (address);
}
