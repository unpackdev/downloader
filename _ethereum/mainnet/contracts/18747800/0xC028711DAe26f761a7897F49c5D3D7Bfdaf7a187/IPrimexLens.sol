// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "./PrimexPricingLibrary.sol";
import "./PositionLibrary.sol";
import "./LimitOrderLibrary.sol";

import "./IPositionManager.sol";
import "./IBucket.sol";
import "./IInterestRateStrategy.sol";
import "./ILiquidityMiningRewardDistributor.sol";

interface IPrimexLens {
    /**
     * @dev A struct to store metadata information of a token.
     * @param tokenAddress The address of the token contract.
     * @param symbol The symbol of the token.
     * @param name The name of the token.
     * @param decimals  The decimal places of the token.
     * @param balance The balance of the token.
     */
    struct TokenMetadata {
        address tokenAddress;
        string symbol;
        string name;
        uint256 decimals;
        uint256 balance;
    }

    /**
     * @param id Id of the asset.
     * @param isSupported Flag indicating if the asset supported in the bucket.
     * @param pairPriceDrop PriceDrop of the trading asset relative to borrowed asset, in WAD format.
     * @param maxLeverage maxAssetLeverage allowed for the trading asset in the bucket, in WAD format.
     */
    struct BucketTokenMetadata {
        uint256 id;
        bool isSupported;
        uint256 pairPriceDrop;
        uint256 maxLeverage;
    }

    /**
     * @param asset Metadata of the asset token as a struct TokenMetadata
     * @param properties Metadata of the bucket token properties as a struct BucketTokenMetadata
     */
    struct SupportedAsset {
        TokenMetadata asset;
        BucketTokenMetadata properties;
    }

    /**
     * @param amountInMining The amount of tokens provided by the lender for mining.
     * @param currentPercent The current percentage of rewards allocated to the lender, in WAD format (1 WAD = 100%)
     * @param rewardsInPMX The expected rewards for the lender in PMX tokens.
     */
    struct LenderInfo {
        uint256 amountInMining;
        uint256 currentPercent;
        ILiquidityMiningRewardDistributor.RewardsInPMX rewardsInPMX;
    }

    /**
     * @dev Struct representing info about a liquidity mining in the bucket.
     * @param pmxAmount Total reward of PMX for liquidity mining in the bucket.
     * @param withdrawnRewards Total reward of PMX amount already withdrawn from the bucket.
     * @param totalPoints Total points accumulated by users in the bucket.
     */
    struct LiquidityMiningBucketInfo {
        uint256 pmxAmount;
        uint256 withdrawnRewards;
        uint256 totalPoints;
    }

    /**
     * @dev Struct representing info about bucket.
     * @param bucketAddress The bucket address.
     * @param name The bucket name.
     * @param asset TokenMetadata of borrowed asset of the bucket.
     * @param bar Borrowing annual rate of the bucket, expressed in RAY.
     * @param lar Lending annual rate of the bucket, expressed in RAY.
     * @param supply Sum of availableLiquidity and demand, in borrowed asset.
     * @param demand Total supply of the debtToken, in borrowed asset.
     * @param availableLiquidity Balance of borrowed asset on the bucket, in borrowed asset.
     * @param utilizationRatio Percentage of the bucket funds used in the loan, in in RAY format (1 RAY = 100%).
     * @param supportedAssets Assets with which you can open a position in the bucket.
     * @param pToken TokenMetadata of pToken of the bucket.
     * @param debtToken TokenMetadata of debtToken of the bucket.
     * @param feeBuffer The fee buffer of the bucket, in WAD format.
     * @param withdrawalFeeRate Percentage of withdrawal that is redirected to the treasury, in WAD format (1 WAD = 100%)
     * @param miningParams Parameters of the bucket liquidity mining.
     * @param lenderInfo Liquidity mining lender information.
     * @param lmBucketInfo Liquidity mining the bucket information.
     * @param estimatedBar Expected value of bar, expressed in RAY
     * @param estimatedLar Expected value of lar., expressed in RAY
     * @param isDeprecated Indicates whether the bucket is outdated and deprecated.
     * @param isDelisted Indicates whether the bucket is delisted.
     * @param barCalcParams The BarCalculationParams struct containing the parameters for calculating bar and lar.
     * @param maxTotalDeposit Max amount of borrowed asset that can be deposited in bucket, in borrowed asset.
     */
    struct BucketMetaData {
        address bucketAddress;
        string name;
        TokenMetadata asset;
        uint128 bar;
        uint128 lar;
        uint256 supply;
        uint256 demand;
        uint256 availableLiquidity;
        uint256 utilizationRatio;
        SupportedAsset[] supportedAssets;
        TokenMetadata pToken;
        TokenMetadata debtToken;
        uint256 feeBuffer;
        uint256 withdrawalFeeRate;
        IBucket.LiquidityMiningParams miningParams;
        LenderInfo lenderInfo;
        LiquidityMiningBucketInfo lmBucketInfo;
        uint128 estimatedBar;
        uint128 estimatedLar;
        bool isDeprecated;
        bool isDelisted;
        IInterestRateStrategy.BarCalculationParams barCalcParams;
        uint256 maxTotalDeposit;
    }

    /**
     * @dev Struct representing the data of a round in an chainlink oracle contract.
     * @param roundId Id of the round.
     * @param answer The answer provided for the round.
     * @param startedAt The timestamp when the round started.
     * @param updatedAt The timestamp when the round was last updated.
     * @param answeredInRound The round in which the answer was provided.
     */
    struct RoundData {
        uint80 roundId;
        int256 answer;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
    }

    /**
     * @dev Structure of open position parameters
     * @param bucket The domain name of the bucket where the position was opened
     * @param borrowedAsset The address of the borrowed asset of this `bucket`
     * @param positionAsset the address of the bought asset of open position
     * @param borrowedAmount the amount of borrowed token in this position
     * @param debt the debt on an open position consists of the loan body and accumulated interest
     * @param depositAmount The amount of deposit trader funds of open position
     * @param healthPosition The parameter determining the riskiness of the position (is averaged to 1).
     * If it is greater than 1, then the position is not risky, if it is less than 1 risky.
     * The decimals of this parameter is determined by the decimals `borrowedAsset`.
     * @param profit An integer showing the profit/loss for open position.
     */
    struct OpenPositionData {
        uint256 id;
        BucketMetaData bucket;
        TokenMetadata[2] pair;
        uint256 positionSize;
        uint256 liquidationPrice;
        uint256 stopLossPrice;
        uint256 takeProfitPrice;
        uint256 debt;
        uint256 depositAmount;
        uint256 createdAt;
    }

    /**
     * @dev Structure for the getPositionStatus function with parameters that show the current status of the position
     * @param liquidationThreshold True if the position is risky
     * @param takeProfitReached True if the position has reached takeProfitAmount
     * @param stopLossReached True if the position has reached stopLossAmount
     */
    struct PositionStatus {
        bool liquidationThreshold;
        bool takeProfitReached;
        bool stopLossReached;
    }

    /**
     * @dev Structure for the getOpenPositionsWithConditions function
     * @param positionData Open position data
     * @param conditionsData Conditions data for corresponding position
     */
    struct OpenPositionWithConditions {
        PositionLibrary.Position positionData;
        LimitOrderLibrary.Condition[] conditionsData;
    }

    /**
     * @dev Structure for the getLimitOrdersWithConditions function
     * @param limitOrderData Limit order data
     * @param openConditionsData Open conditions data for corresponding order
     */
    struct LimitOrderWithConditions {
        LimitOrderLibrary.LimitOrder limitOrderData;
        LimitOrderLibrary.Condition[] openConditionsData;
    }

    /**
     * @notice Retrieves open position data based on the provided position manager and id.
     * @param _positionManager The address of the PositionManager where the position is stored
     * @param _id Position id to show the parameters position
     * @return openPositionData The open position data including various details.
     */
    function getOpenPositionData(address _positionManager, uint256 _id) external returns (OpenPositionData memory);

    /**
     * @notice The function shows the parameters for all open positions of the `_trader` with the best dex for each position
     * @param _positionManager The address of the PositionManager where the positions is stored
     * @param _trader The address, information about all positions of which will be displayed
     * @param _cursor The cursor value for pagination.
     * @param _count The number of positions to retrieve.
     */
    function getArrayOpenPositionDataByTrader(
        address _positionManager,
        address _trader,
        uint256 _cursor,
        uint256 _count
    ) external returns (OpenPositionData[] memory, uint256);

    /**
     * @notice The function shows the parameters for all open positions of the `_trader` with the best dex for each position
     * @param _positionManager The address of the PositionManager where the positions is stored
     * @param _bucket The address of the bucket positions are related to
     * @param _cursor The cursor value for pagination.
     * @param _count The number of positions to retrieve.
     */
    function getArrayOpenPositionDataByBucket(
        address _positionManager,
        address _bucket,
        uint256 _cursor,
        uint256 _count
    ) external returns (OpenPositionData[] memory, uint256);

    /**
     * @notice Retrieves the status of a position.
     * @param _positionManager The address of the PositionManager where the position is stored
     * @param _id Position id to show the parameters position
     * @param _routes An array of route objects representing the pricing routes.
     * @return positionStatus The status of the position.
     */
    function getPositionStatus(
        address _positionManager,
        uint256 _id,
        PrimexPricingLibrary.Route[] calldata _routes
    ) external returns (PositionStatus memory);

    /**
     * @notice Checks if the take profit condition is reached for a given position.
     * @param _positionManager The address of the PositionManager contract.
     * @param _id The ID of the position to check.
     * @param _routes The routes for pricing the position.
     * @return A boolean indicating whether the take profit condition is reached.
     */
    function isTakeProfitReached(
        address _positionManager,
        uint256 _id,
        PrimexPricingLibrary.Route[] calldata _routes
    ) external returns (bool);

    /**
     * @notice The function returns the limit orders with corresponding conditions
     * @param _limitOrderManager The address of the LimitOrderManager where the order is stored.
     * @param _cursor The cursor value for pagination.
     * @param _count The number of positions to retrieve.
     * @return limitOrderWithConditions An array of LimitOrderWithConditions structs representing open positions with conditions.
     * @return newCursor The new cursor value for pagination.
     */
    function getLimitOrdersWithConditions(
        address _limitOrderManager,
        uint256 _cursor,
        uint256 _count
    ) external view returns (LimitOrderWithConditions[] memory, uint256 newCursor);

    /**
     * @notice The function returns the positions with corresponding conditions.
     * @param _positionManager The address of the PositionManager where the position is stored.
     * @param _cursor The cursor value for pagination.
     * @param _count The number of positions to retrieve.
     * @return openPositionsWithConditionsArray An array of OpenPositionWithConditions structs representing open positions with conditions.
     * @return newCursor The new cursor value for pagination.
     */
    function getOpenPositionsWithConditions(
        address _positionManager,
        uint256 _cursor,
        uint256 _count
    ) external view returns (OpenPositionWithConditions[] memory, uint256 newCursor);

    /**
     * @notice Retrieves the metadata of a token for a given trader.
     * @param _token The address of the token.
     * @param _trader The address of the trader.
     * @return metadata The metadata of the token.
     */
    function getTokenMetadata(address _token, address _trader) external view returns (TokenMetadata memory);

    /**
     * @notice Retrieves the metadata of an array of tokens for a given trader.
     * @param _tokens The array of token addresses.
     * @param _trader The address of the trader.
     * @return res The array of token metadata.
     */
    function getTokenArrayMetadata(
        address[] calldata _tokens,
        address _trader
    ) external view returns (TokenMetadata[] memory);

    /**
     * @notice Retrieves the metadata of an asset within a bucket.
     * @param _bucket The address of the Bucket contract.
     * @param _asset The address of the asset to retrieve metadata for.
     * @return metadata The metadata of the asset within the bucket.
     */
    function getAssetMetadata(address _bucket, address _asset) external view returns (BucketTokenMetadata memory);

    /**
     * @notice Retrieves information about a supported asset.
     * @param _bucket The address of the Bucket where the asset is supported.
     * @param _asset The address of the asset for which information is requested.
     * @param _trader The address of the Trader requesting the information.
     * @return supportedAsset The SupportedAsset struct containing the asset and its properties.
     */
    function getSupportedAsset(
        address _bucket,
        address _asset,
        address _trader
    ) external view returns (SupportedAsset memory);

    /**
     * @notice Retrieves an array of SupportedAsset structs for the given bucket, assets, and trader.
     * @param _bucket The address of the Bucket.
     * @param _assets An array of asset addresses.
     * @param _trader The address of the trader.
     * @return res An array of SupportedAsset structs representing the supported assets.
     */
    function getSupportedAssetArray(
        address _bucket,
        address[] memory _assets,
        address _trader
    ) external view returns (SupportedAsset[] memory);

    /**
     * @notice Retrieves the metadata of a bucket.
     * @param _bucket The address of the Bucket contract.
     * @param _trader The address of the trader.
     * @return The metadata of the bucket.
     */
    function getBucket(address _bucket, address _trader) external view returns (BucketMetaData memory);

    /**
     * @notice Retrieves an array of `BucketMetaData` for the given `_user`.
     * @param _buckets The array of bucket addresses.
     * @param _trader The address of the trader.
     * @param _positionManager The address of the PositionManager contract.
     * @param _showDeprecated Flag to determine whether deprecated buckets should be included.
     * @return An array of `BucketMetaData` objects.
     */
    function getBucketsArray(
        address[] memory _buckets,
        address _trader,
        address _positionManager,
        bool _showDeprecated
    ) external view returns (BucketMetaData[] memory);

    /**
     * @notice Retrieves all bucket metadata from a bucket factory contract.
     * @param _bucketFactory The address of the BucketFactory contract.
     * @param _trader The address of the trader for whom the buckets are retrieved.
     * @param _positionManager The address of the PositionManager contract.
     * @param _showDeprecated A boolean flag indicating whether to include deprecated buckets in the result.
     * @return An array of BucketMetaData structs representing the bucket metadata.
     */
    function getAllBucketsFactory(
        address _bucketFactory,
        address _trader,
        address _positionManager,
        bool _showDeprecated
    ) external view returns (BucketMetaData[] memory);

    /**
     * @notice Retrieves the latest round data for multiple Chainlink feeds.
     * @param _feeds An array of feed addresses.
     * @return res An array of RoundData structs containing the latest round data for each feed.
     */
    function getChainlinkLatestRoundData(address[] calldata _feeds) external view returns (RoundData[] memory);

    /**
     * @notice Calculates the liquidation price for a given position.
     * @dev The liquidation price is the price at which a position can be liquidated (i.e., its collateral can cover the borrowed amount).
     * @param _positionManager The address of the PositionManager contract.
     * @param _bucket The name of the bucket associated with the position.
     * @param _borrowedAmount The amount borrowed in the position.
     * @param _positionAsset The address of the asset held in the position.
     * @param _positionAmount The amount of the asset held in the position.
     * @return The liquidation price in borrowed asset for the position.
     */
    function getLiquidationPrice(
        address _positionManager,
        string memory _bucket,
        uint256 _borrowedAmount,
        address _positionAsset,
        uint256 _positionAmount
    ) external view returns (uint256);

    /**
     * @notice Retrieves the liquidation price of a position.
     * @param _positionManager The address of the PositionManager contract.
     * @param _id The ID of the position.
     * @return The liquidation price in borrowed asset of the position.
     */
    function getLiquidationPrice(address _positionManager, uint256 _id) external view returns (uint256);

    /**
     * @notice Checks if the stop loss condition of a position is reached.
     * @param _positionManager The address of the PositionManager contract.
     * @param _id The ID of the position to check.
     * @return A boolean indicating whether the stop loss condition is reached.
     */
    function isStopLossReached(address _positionManager, uint256 _id) external view returns (bool);

    /**
     * @notice Retrieves the maximum decrease in position value for a given position ID.
     * @dev maxDecrease = (1 - securityBuffer) * (1 - oracleTolerableLimit) * (1 - pricedrop) * borrowedAssetAmountOut /
     * (feeBuffer * (1 + maintenanceBuffer)) - position.bucket.getNormalizedVariableDebt() * position.scaledDebtAmount
     * @param _pm The instance of the PositionManager contract.
     * @param _id The ID of the position.
     * @return The maximum decrease in position value.
     */
    function getPositionMaxDecrease(IPositionManager _pm, uint256 _id) external view returns (uint256);

    /**
     * @notice Retrieves information about a lender from the LiquidityMiningRewardDistributor contract.
     * @param liquidityMiningRewardDistributor The instance of the LiquidityMiningRewardDistributor contract.
     * @param bucketName The name of the lending bucket.
     * @param user The address of the lender.
     * @return info The lender information.
     */
    function getLenderInfo(
        ILiquidityMiningRewardDistributor liquidityMiningRewardDistributor,
        string memory bucketName,
        address user
    ) external view returns (LenderInfo memory);

    /**
     * @notice Retrieves information about a liquidity mining bucket.
     * @param liquidityMiningRewardDistributor The instance of the LiquidityMiningRewardDistributor contract.
     * @param _bucketName The name of the liquidity mining bucket.
     * @return info The liquidity mining bucket information.
     */
    function getLMBucketInfo(
        ILiquidityMiningRewardDistributor liquidityMiningRewardDistributor,
        string memory _bucketName
    ) external view returns (LiquidityMiningBucketInfo memory);
}
