// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "./IERC20Metadata.sol";

import "./PrimexPricingLibrary.sol";

import "./IPToken.sol";
import "./IDebtToken.sol";
import "./IPositionManager.sol";
import "./IPriceOracle.sol";
import "./IPrimexDNS.sol";
import "./IWhiteBlackList.sol";
import "./IReserve.sol";
import "./ILiquidityMiningRewardDistributor.sol";
import "./IInterestRateStrategy.sol";
import "./ISwapManager.sol";
import "./IBucketStorage.sol";

interface IBucket is IBucketStorage {
    struct ConstructorParams {
        string name;
        IPToken pToken;
        IDebtToken debtToken;
        IPositionManager positionManager;
        IPriceOracle priceOracle;
        IPrimexDNS dns;
        IReserve reserve;
        IWhiteBlackList whiteBlackList;
        address[] assets;
        IERC20Metadata borrowedAsset;
        uint256 feeBuffer;
        uint256 withdrawalFeeRate;
        uint256 reserveRate;
        // liquidityMining params
        ILiquidityMiningRewardDistributor liquidityMiningRewardDistributor;
        uint256 liquidityMiningAmount;
        uint256 liquidityMiningDeadline;
        uint256 stabilizationDuration;
        IInterestRateStrategy interestRateStrategy;
        uint128 estimatedBar;
        uint128 estimatedLar;
        uint256 maxAmountPerUser;
        bool isReinvestToAaveEnabled;
        bytes barCalcParams;
        uint256 maxTotalDeposit;
    }

    event Deposit(address indexed depositer, address indexed pTokenReceiver, uint256 amount);

    event Withdraw(address indexed withdrawer, address indexed borrowAssetReceiver, uint256 amount);

    event DepositToAave(address indexed pool, uint256 amount);

    event WithdrawFromAave(address indexed pool, uint256 amount);

    event TopUpTreasury(address indexed sender, uint256 amount);

    event FeeBufferChanged(uint256 feeBuffer);

    event ReserveRateChanged(uint256 reserveRate);

    event RatesIndexesUpdated(
        uint128 bar,
        uint128 lar,
        uint128 variableBorrowIndex,
        uint128 liquidityIndex,
        uint256 timestamp
    );

    event WithdrawalFeeChanged(uint256 withdrawalFeeRate);

    event InterestRateStrategyChanged(address interestRateStrategy);

    event AddAsset(address addedAsset);

    event RemoveAsset(address deletedAsset);

    event MaxTotalDepositChanged(uint256 maxTotalDeposit);

    event BarCalculationParamsChanged(bytes params);

    event BucketLaunched();

    /**
     * @dev Initializes the contract with the given parameters.
     * @param _params The ConstructorParams struct containing initialization parameters.
     * @param _registry The address of the registry contract.
     */
    function initialize(ConstructorParams memory _params, address _registry) external;

    /**
     * @dev Function to add new trading asset for this bucket
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param _newAsset The address of trading asset
     */
    function addAsset(address _newAsset) external;

    /**
     * @notice Removes a trading asset from this bucket.
     * @dev Only callable by the SMALL_TIMELOCK_ADMIN role.
     * @param _assetToDelete The address of the asset to be removed.
     */
    function removeAsset(address _assetToDelete) external;

    function setBarCalculationParams(bytes memory _params) external;

    /**
     * @dev Sets the reserve rate.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param _reserveRate The new reserve rate value.
     */
    function setReserveRate(uint256 _reserveRate) external;

    /**
     * @dev Sets the new fee buffer.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param _feeBuffer The new fee buffer value.
     */
    function setFeeBuffer(uint256 _feeBuffer) external;

    /**
     * @dev Sets the withdrawal fee.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param _withdrawalFee The new withdrawal fee value.
     */
    function setWithdrawalFee(uint256 _withdrawalFee) external;

    /**
     * @dev Sets the interest rate strategy contract address.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param _interestRateStrategy The address of the interest rate strategy contract.
     */
    function setInterestRateStrategy(address _interestRateStrategy) external;

    /**
     * @notice The function sets the max total deposit for the particular bucket
     * @param _maxTotalDeposit The amount of max total deposit for the bucket
     */
    function setMaxTotalDeposit(uint256 _maxTotalDeposit) external;

    /**
     * @dev Deposits the 'amount' of underlying asset into the bucket. The 'PTokenReceiver' receives overlying pTokens.
     * @param _pTokenReceiver The address to receive the deposited pTokens.
     * @param _amount The amount of underlying tokens to be deposited
     */
    function deposit(address _pTokenReceiver, uint256 _amount) external;

    /**
     * @dev Withdraws the 'amount' of underlying asset from the bucket. The 'amount' of overlying pTokens will be burned.
     * @param _borrowAssetReceiver The address of receiver of the borrowed asset.
     * @param amount The amount of underlying tokens to be withdrawn.
     */
    function withdraw(address _borrowAssetReceiver, uint256 amount) external;

    /**
     * @notice Allows the BIG_TIMELOCK_ADMIN role to withdraw a specified amount of tokens after delisting.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawAfterDelisting(uint256 _amount) external;

    /**
     * @dev Receives a deposit and distributes it to the specified pToken receiver.
     * @dev Can be called only by another bucket.
     * @param _pTokenReceiver The address of the recipient of the pToken.
     * @param _amount The amount of tokens being deposited.
     * @param _duration The blocking time for a fixed-term deposit (if it's 0, then it will be a usual deposit)
     * @param _bucketFrom The name of the bucket from which the deposit is being made.
     */
    function receiveDeposit(
        address _pTokenReceiver,
        uint256 _amount,
        uint256 _duration,
        string memory _bucketFrom
    ) external;

    /**
     * @notice Deposits (reinvests) funds from a bucket to another bucket.
     * Used only in the case of failed liquidity mining in the bucket from where the transfer happens.
     * @param _bucketTo The name of the destination bucket.
     * @param _swapManager The address of the swap manager.
     * @param routes The array of routes for swapping tokens.
     * @param _amountOutMin The minimum amount of tokens to receive from the swap.
     */
    function depositFromBucket(
        string calldata _bucketTo,
        ISwapManager _swapManager,
        PrimexPricingLibrary.Route[] calldata routes,
        uint256 _amountOutMin
    ) external;

    /**
     * @dev Allows the SMALL_TIMELOCK_ADMIN to withdraw all liquidity from Aave to Bucket.
     */
    function returnLiquidityFromAaveToBucket() external;

    /**
     * @dev Function to update rates and indexes when a trader opens a trading position.
     * Mints debt tokens to trader. Calls only by positionManager contract.
     * @param _trader The address of the trader, who opens position.
     * @param _amount The 'amount' for which the deal is open, and 'amount' of debtTokens will be minted to the trader.
     * @param _to The address to transfer the borrowed asset to.
     */

    function increaseDebt(address _trader, uint256 _amount, address _to) external;

    /**
     * @dev Function to update rates and indexes.
     * Burns debt tokens of trader. Called only by positionManager contract.
     * @param _trader The address of the trader, who opened position.
     * @param _debtToBurn The 'amount' of trader's debtTokens will be burned by the trader.
     * @param _receiverOfAmountToReturn Treasury in case of liquidation. TraderBalanceVault in other cases
     * @param _amountToReturn Amount to transfer from bucket
     * @param _permanentLossAmount The amount of the protocol's debt to creditors accrued for this position
     */
    function decreaseTraderDebt(
        address _trader,
        uint256 _debtToBurn,
        address _receiverOfAmountToReturn,
        uint256 _amountToReturn,
        uint256 _permanentLossAmount
    ) external;

    /**
     * @notice Batch decreases the debt of multiple traders.
     * @dev This function can only be called by the BATCH_MANAGER_ROLE.
     * @param _traders An array of addresses representing the traders.
     * @param _debtsToBurn An array of uint256 values representing the debts to burn for each trader.
     * @param _receiverOfAmountToReturn The address that will receive the amount to be returned.
     * @param _amountToReturn The amount to be returned.
     * @param _permanentLossAmount The amount of permanent loss.
     * @param _length The length of the traders array.
     */
    function batchDecreaseTradersDebt(
        address[] memory _traders,
        uint256[] memory _debtsToBurn,
        address _receiverOfAmountToReturn,
        uint256 _amountToReturn,
        uint256 _permanentLossAmount,
        uint256 _length
    ) external;

    /**
     * @notice This function allows a user to pay back a permanent loss by burning his pTokens.
     * @param amount The amount of pTokens to be burned to pay back the permanent loss.
     */
    function paybackPermanentLoss(uint256 amount) external;

    /**
     * @dev Calculates the permanent loss based on the scaled permanent loss and the normalized income.
     * @return The amount of permanent loss.
     */
    function permanentLoss() external view returns (uint256);

    /**
     * @dev Checks if the bucket is deprecated in the protocol.
     * @return Whether the bucket is deprecated or not.
     */
    function isDeprecated() external view returns (bool);

    /**
     * @dev Returns a boolean value indicating whether the bucket is delisted.
     * @return True if the bucket is delisted, otherwise false.
     */
    function isDelisted() external view returns (bool);

    /**
     * @dev Checks if an admin can withdraw from the bucket after delisting.
     * @return A boolean indicating whether withdrawal is available.
     */
    function isWithdrawAfterDelistingAvailable() external view returns (bool);

    /**
     * @dev Checks if this bucket is active in the protocol.
     * @return bool True if the bucket is active, false otherwise.
     */
    function isActive() external view returns (bool);

    /**
     * @dev Returns the parameters for liquidity mining.
     * @return LMparams The liquidity mining parameters.
     */
    function getLiquidityMiningParams() external view returns (LiquidityMiningParams memory);

    /**
     * @dev Returns a boolean value indicating whether the bucket is stable in the liquidity mining event.
     * @return A boolean value representing the stability of the bucket.
     */
    function isBucketStable() external view returns (bool);

    /**
     * @dev Calculates the max leverage according to the following formula:
     * ((1 + maintenanceBuffer) * feeBuffer) / ((1 + maintenanceBuffer) * feeBuffer - (1 - securityBuffer) *
     * (1 - pairPriceDropBA) * (1 - oracleTolerableLimitAB) * (1 - oracleTolerableLimitBA))
     * @param _asset The address of trading asset
     * @return The maximum leverage as a uint256 value.
     */
    function maxAssetLeverage(address _asset) external view returns (uint256);

    /**
     * @dev Returns the normalized income per unit of underlying asset, expressed in ray
     * @return The normalized income per unit of underlying asset, expressed in ray
     */
    function getNormalizedIncome() external view returns (uint256);

    /**
     * @dev Returns the normalized variable debt per unit of underlying asset, expressed in ray
     */
    function getNormalizedVariableDebt() external view returns (uint256);

    /**
     * @dev Returns allowed trading assets for current bucket
     * @return List of addresses of allowed assets
     */
    function getAllowedAssets() external view returns (address[] memory);

    /**
     * @dev Returns current avalable liquidity of borrowedAsset for trading.
     * @return The amount of available borrowedAsset
     */
    function availableLiquidity() external view returns (uint256);
}

interface IBucketV2 is IBucket {
    /**
     * @dev Deposits the 'amount' of underlying asset into the bucket. The 'PTokenReceiver' receives overlying pTokens.
     * @param _pTokenReceiver The address to receive the deposited pTokens.
     * @param _amount The amount of underlying tokens to be deposited
     * @param _takeDepositFromWallet A flag indicating whether to make the deposit from user wallet
     */
    function deposit(address _pTokenReceiver, uint256 _amount, bool _takeDepositFromWallet) external;
}
