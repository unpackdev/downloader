// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./AccessControl.sol";
import "./Multicall.sol";

import "./ILiquidation.sol";
import "./ErrorCodes.sol";
import "./InterconnectorLeaf.sol";

/**
 * This contract provides the liquidation functionality.
 */
contract Liquidation is ILiquidation, AccessControl, ReentrancyGuard, Multicall, InterconnectorLeaf {
    using SafeERC20 for IERC20;

    /// @notice Value is the Keccak-256 hash of "TRUSTED_LIQUIDATOR"
    /// @dev Role that's allowed to execute liquidateUnsafeLoan function
    bytes32 public constant TRUSTED_LIQUIDATOR =
        bytes32(0xf81d27a41879d78d5568e0bc2989cb321b89b84d8e1b49895ee98604626c0218);
    /// @dev Value is the Keccak-256 hash of "TIMELOCK"
    bytes32 public constant TIMELOCK = bytes32(0xaefebe170cbaff0af052a32795af0e1b8afff9850f946ad2869be14f35534371);

    uint256 private constant EXP_SCALE = 1e18;

    /**
     * @notice Minterest supervisor contract
     */
    ISupervisor public immutable supervisor;

    /**
     * @notice The maximum allowable value of a healthy factor after liquidation, scaled by 1e18
     */
    uint256 public healthyFactorLimit = 1.2e18; // 120%

    /**
     * @notice Construct a Liquidation contract
     * @param liquidators_ Array of addresses of liquidators
     * @param supervisor_ The address of the Supervisor contract
     * @param admin_ The address of the admin
     */
    constructor(
        address[] memory liquidators_,
        ISupervisor supervisor_,
        address admin_
    ) {
        require(address(supervisor_) != address(0), ErrorCodes.ZERO_ADDRESS);
        require(admin_ != address(0), ErrorCodes.ZERO_ADDRESS);

        supervisor = supervisor_;
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(TRUSTED_LIQUIDATOR, admin_);
        _grantRole(TIMELOCK, admin_);

        for (uint256 i = 0; i < liquidators_.length; i++) {
            _grantRole(TRUSTED_LIQUIDATOR, liquidators_[i]);
        }
    }

    /// @inheritdoc ILiquidation
    function liquidateUnsafeLoan(
        IMToken seizeMarket_,
        IMToken repayMarket_,
        address borrower_,
        uint256 repayAmount_
    ) external onlyRole(TRUSTED_LIQUIDATOR) nonReentrant returns (uint256, uint256) {
        AccountLiquidationAmounts memory accountState;

        IMToken[] memory accountAssets = supervisor.getAccountAssets(borrower_);

        verifyExternalData(accountAssets, seizeMarket_, repayMarket_, repayAmount_);

        accrue(seizeMarket_, repayMarket_);
        accountState = calculateLiquidationAmounts(borrower_, accountAssets, seizeMarket_, repayMarket_, repayAmount_);
        require(
            accountState.accountTotalCollateralUsd < accountState.accountTotalBorrowUsd,
            ErrorCodes.INSUFFICIENT_SHORTFALL
        );

        bool isDebtHealthy = accountState.accountPresumedTotalRepayUsd >= accountState.accountTotalBorrowUsd;

        if (isDebtHealthy) {
            require(approveBorrowerHealthyFactor(accountState), ErrorCodes.HEALTHY_FACTOR_NOT_IN_RANGE);
        }

        seizeMarket_.autoLiquidationSeize(borrower_, accountState.seizeAmount, false, msg.sender);

        repayMarket_.addProtocolInterestBehalf(msg.sender, repayAmount_);
        repayMarket_.autoLiquidationRepayBorrow(borrower_, repayAmount_);

        emit ReliableLiquidation(
            isDebtHealthy,
            msg.sender,
            borrower_,
            seizeMarket_,
            repayMarket_,
            accountState.seizeAmount,
            repayAmount_
        );

        return (accountState.seizeAmount, repayAmount_);
    }

    /// @inheritdoc ILiquidation
    function accrue(IMToken seizeMarket, IMToken repayMarket) public {
        repayMarket.accrueInterest();
        seizeMarket.accrueInterest();
    }

    /**
     * @dev Local marketParams for avoiding stack-depth limits in calculating liquidation amounts.
     */
    struct MarketParams {
        uint256 supplyWrap;
        uint256 borrowUnderlying;
        uint256 exchangeRateMantissa;
        uint256 liquidationFeeMantissa;
        uint256 utilisationFactorMantissa;
    }

    /**
     * @dev Local liquidationParams for avoiding stack-depth limits in calculating liquidation amounts.
     */
    struct LocalLiquidationParams {
        uint256 accountTotalRepayUsd;
        uint256 targetPresumedRepayUsd;
        uint256 targetLiquidationFeeMultiplier;
        uint256 targetUtilizationFactor;
        uint256 seizeMarketIndex;
    }

    /// @inheritdoc ILiquidation
    function calculateLiquidationAmounts(
        address account_,
        IMToken[] memory marketAddresses,
        IMToken seizeMarket,
        IMToken repayMarket,
        uint256 repayAmount
    ) public view virtual returns (AccountLiquidationAmounts memory accountState) {
        IPriceOracle cachedOracle = oracle();
        // slither-disable-next-line uninitialized-local
        LocalLiquidationParams memory localParams;

        uint256[] memory oraclePrices = new uint256[](marketAddresses.length);

        // calculate liquidation amounts for each market the borrower is in,
        // update accountState with accumulated values within the same loop
        for (uint256 i = 0; i < marketAddresses.length; i++) {
            IMToken market = marketAddresses[i];

            // oracle price of each processed token must exist
            oraclePrices[i] = cachedOracle.getUnderlyingPrice(market);
            require(oraclePrices[i] > 0, ErrorCodes.INVALID_PRICE);

            // slither-disable-next-line uninitialized-local
            MarketParams memory vars;
            (vars.supplyWrap, vars.borrowUnderlying, vars.exchangeRateMantissa) = market.getAccountSnapshot(account_);
            (vars.liquidationFeeMantissa, vars.utilisationFactorMantissa) = supervisor.getMarketData(market);

            // account position has borrowed assets in the market
            if (vars.borrowUnderlying > 0) {
                // collect accumulated value of accountState.accountTotalBorrowUsd:
                // accountTotalBorrowUsd += borrowUnderlying * oraclePrice
                uint256 accountBorrowUsd = (vars.borrowUnderlying * oraclePrices[i]) / EXP_SCALE;
                accountState.accountTotalBorrowUsd += accountBorrowUsd;

                // there is a debt on this market that should be repaid
                if (repayMarket == market) {
                    require(vars.borrowUnderlying >= repayAmount, ErrorCodes.LQ_INCORRECT_REPAY_AMOUNT);
                    localParams.accountTotalRepayUsd = (repayAmount * oraclePrices[i]) / EXP_SCALE;
                }
            }

            // account position has supplied assets in the market
            if (vars.supplyWrap > 0) {
                // (1 + liquidationFee) value is stored for the future use as liquidationFeeMultipliers
                uint256 liquidationFeeMultiplier = vars.liquidationFeeMantissa + EXP_SCALE;

                // supplyAmount = supplyWrap * exchangeRate
                uint256 supplyAmount = (vars.supplyWrap * vars.exchangeRateMantissa) / EXP_SCALE;
                uint256 accountSupplyUsd = (supplyAmount * oraclePrices[i]) / EXP_SCALE;

                // presumed repay in USD is a portion of the debt that is coverable by the current supply
                uint256 presumedRepayUsd = ((accountSupplyUsd * EXP_SCALE) / liquidationFeeMultiplier);

                // collect accumulated value of accountState.accountPresumedTotalRepayUsd:
                // accountPresumedTotalRepayUsd value means what the totalRepay would be possible
                // under the condition of complete liquidation.
                accountState.accountPresumedTotalRepayUsd += presumedRepayUsd;

                // collect accumulated value of accountState.accountTotalSupplyUsd:
                // accountTotalSupplyUsd += supplyWrap * exchangeRate * oraclePrice
                accountState.accountTotalSupplyUsd += accountSupplyUsd;

                // accountTotalCollateralUsd += accountSupplyUsd * utilisationFactor
                accountState.accountTotalCollateralUsd +=
                    (accountSupplyUsd * vars.utilisationFactorMantissa) /
                    EXP_SCALE;

                if (seizeMarket == market) {
                    localParams.targetPresumedRepayUsd = presumedRepayUsd;
                    localParams.targetLiquidationFeeMultiplier = liquidationFeeMultiplier;
                    localParams.targetUtilizationFactor = vars.utilisationFactorMantissa;
                    localParams.seizeMarketIndex = i;
                }
            }
        }

        if (localParams.accountTotalRepayUsd > 0) {
            require(
                localParams.accountTotalRepayUsd <= localParams.targetPresumedRepayUsd,
                ErrorCodes.LQ_INSUFFICIENT_SEIZE_AMOUNT
            );

            uint256 seizeAmountUsd = (localParams.accountTotalRepayUsd * localParams.targetLiquidationFeeMultiplier) /
                EXP_SCALE;
            uint256 seizeCollateralUsd = (seizeAmountUsd * localParams.targetUtilizationFactor) / EXP_SCALE;

            accountState.accountTotalCollateralUsdAfter = accountState.accountTotalCollateralUsd - seizeCollateralUsd;
            accountState.accountTotalBorrowUsdAfter =
                accountState.accountTotalBorrowUsd -
                localParams.accountTotalRepayUsd;

            accountState.seizeAmount = (seizeAmountUsd * EXP_SCALE) / oraclePrices[localParams.seizeMarketIndex];
        }

        return accountState;
    }

    /**
     * @dev Approve that healthy factor after liquidation satisfies the condition:
     *      newHealthyFactor <= healthyFactorLimit
     * @param accountState Struct that contains all balance parameters
     *         All total values calculated in USD.
     * @return Whether or not the current account healthy factor is correct
     */
    function approveBorrowerHealthyFactor(AccountLiquidationAmounts memory accountState) internal view returns (bool) {
        require(accountState.accountTotalBorrowUsdAfter > 0, ErrorCodes.LQ_UNSUPPORTED_FULL_REPAY);
        require(accountState.accountTotalCollateralUsdAfter > 0, ErrorCodes.LQ_UNSUPPORTED_FULL_SEIZE);
        uint256 newHealthyFactor = (accountState.accountTotalCollateralUsdAfter * EXP_SCALE) /
            accountState.accountTotalBorrowUsdAfter;

        return (newHealthyFactor <= healthyFactorLimit);
    }

    /**
     * @dev Approve that received params are correct
     * @param accountAssets An array with addresses of markets where the debtor is in
     * @param seizeMarket Market from which the account's collateral will be seized
     * @param repayMarket Market from which the account's debt will be repaid
     * @param repayAmount Amount of debt to be repaid
     */
    function verifyExternalData(
        IMToken[] memory accountAssets,
        IMToken seizeMarket,
        IMToken repayMarket,
        uint256 repayAmount
    ) internal pure {
        require(repayAmount > 0, ErrorCodes.LQ_INCORRECT_REPAY_AMOUNT);

        bool isSeizeMarketCorrect = false;
        bool isRepayMarketCorrect = false;
        for (uint256 i = 0; i < accountAssets.length; i++) {
            if (accountAssets[i] == seizeMarket) isSeizeMarketCorrect = true;
            if (accountAssets[i] == repayMarket) isRepayMarketCorrect = true;
        }
        require(isSeizeMarketCorrect && isRepayMarketCorrect, ErrorCodes.LQ_UNSUPPORTED_MARKET_RECEIVED);
    }

    /*** Admin Functions ***/

    /// @inheritdoc ILiquidation
    function setHealthyFactorLimit(uint256 newValue_) external onlyRole(TIMELOCK) {
        uint256 oldValue = healthyFactorLimit;

        require(newValue_ != oldValue, ErrorCodes.IDENTICAL_VALUE);
        healthyFactorLimit = newValue_;

        emit HealthyFactorLimitChanged(oldValue, newValue_);
    }

    /// @notice get contract PriceOracle
    function oracle() internal view returns (IPriceOracle) {
        return getInterconnector().oracle();
    }
}
