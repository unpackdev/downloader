// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import "./IERC20.sol";
import "./INToken.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./IReserveInterestRateStrategy.sol";
import "./IScaledBalanceToken.sol";
import "./IPriceOracleGetter.sol";
import "./IYToken.sol";
import "./IPriceOracleSentinel.sol";
import "./IPoolAddressesProvider.sol";
import "./IAccessControl.sol";
import "./ReserveConfiguration.sol";
import "./UserConfiguration.sol";
import "./UserERC1155Configuration.sol";
import "./Errors.sol";
import "./WadRayMath.sol";
import "./PercentageMath.sol";
import "./DataTypes.sol";
import "./ReserveLogic.sol";
import "./GenericLogic.sol";
import "./SafeCast.sol";
import "./IncentivizedERC20.sol";

/**
 * @title ReserveLogic library
 *
 * @notice Implements functions to validate the different actions of the protocol
 */
library ValidationLogic {
    using ReserveLogic for DataTypes.ReserveData;
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using SafeCast for uint256;
    using SafeERC20 for IERC20;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;
    using UserERC1155Configuration for DataTypes.UserERC1155ConfigurationMap;
    using Address for address;

    // Factor to apply to "only-variable-debt" liquidity rate to get threshold for rebalancing, expressed in bps
    // A value of 0.9e4 results in 90%
    uint256 public constant REBALANCE_UP_LIQUIDITY_RATE_THRESHOLD = 0.9e4;

    // Minimum health factor allowed under any circumstance
    // A value of 0.95e18 results in 0.95
    uint256 public constant MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 0.95e18;

    /**
     * @dev Minimum health factor to consider a user position healthy
     * A value of 1e18 results in 1
     */
    uint256 public constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1e18;

    /**
     * @notice Validates a supply action.
     * @param reserveCache The cached data of the reserve
     * @param amount The amount to be supplied
     */
    function validateSupply(
        DataTypes.ReserveCache memory reserveCache,
        DataTypes.ReserveData storage reserve,
        uint256 amount
    ) internal view {
        require(amount != 0, Errors.INVALID_AMOUNT);

        (bool isActive, bool isFrozen,, bool isPaused) = reserveCache.reserveConfiguration.getFlags();
        require(isActive, Errors.RESERVE_INACTIVE);
        require(!isPaused, Errors.RESERVE_PAUSED);
        require(!isFrozen, Errors.RESERVE_FROZEN);

        uint256 supplyCap = reserveCache.reserveConfiguration.getSupplyCap();
        require(
            supplyCap == 0
                || (
                    (IYToken(reserveCache.yTokenAddress).scaledTotalSupply() + uint256(reserve.accruedToTreasury)).rayMul(
                        reserveCache.nextLiquidityIndex
                    ) + amount
                ) <= supplyCap * (10 ** reserveCache.reserveConfiguration.getDecimals()),
            Errors.SUPPLY_CAP_EXCEEDED
        );
    }

    /**
     * @notice Validates a supply action.
     * @param reserveConfig The config of the reserve
     * @param amount The amount to be supplied
     */
    function validateSupplyERC1155(
        DataTypes.ERC1155ReserveConfiguration memory reserveConfig,
        DataTypes.UserERC1155ConfigurationMap storage userERC1155Config,
        address underlying,
        uint256 tokenId,
        uint256 amount,
        uint256 maxERC1155CollateralReserves
    ) internal view {
        require(amount != 0, Errors.INVALID_AMOUNT);

        require(reserveConfig.isActive, Errors.RESERVE_INACTIVE);
        require(!reserveConfig.isPaused, Errors.RESERVE_PAUSED);
        require(!reserveConfig.isFrozen, Errors.RESERVE_FROZEN);

        if (!userERC1155Config.isUsingAsCollateral(underlying, tokenId)) {
            require(
                validateUseERC1155AsCollateral(reserveConfig, userERC1155Config, maxERC1155CollateralReserves),
                Errors.ERC1155_RESERVE_CANNOT_BE_USED_AS_COLLATERAL
            );
        }
    }

    /**
     * @notice Validates a withdraw action.
     * @param reserveCache The cached data of the reserve
     * @param amount The amount to be withdrawn
     * @param userBalance The balance of the user
     */
    function validateWithdraw(DataTypes.ReserveCache memory reserveCache, uint256 amount, uint256 userBalance)
        internal
        pure
    {
        require(amount != 0, Errors.INVALID_AMOUNT);
        require(amount <= userBalance, Errors.NOT_ENOUGH_AVAILABLE_USER_BALANCE);

        (bool isActive,,, bool isPaused) = reserveCache.reserveConfiguration.getFlags();
        require(isActive, Errors.RESERVE_INACTIVE);
        require(!isPaused, Errors.RESERVE_PAUSED);
    }

    /**
     * @notice Validates a withdrawERC1155 action.
     * @param reserveConfig The config of the reserve
     * @param amount The amount to be withdrawn
     * @param userBalance The balance of the user
     */
    function validateWithdrawERC1155(
        DataTypes.ERC1155ReserveConfiguration memory reserveConfig,
        uint256 amount,
        uint256 userBalance
    ) internal pure {
        require(amount != 0, Errors.INVALID_AMOUNT);
        require(amount <= userBalance, Errors.NOT_ENOUGH_AVAILABLE_USER_BALANCE);

        require(reserveConfig.isActive, Errors.RESERVE_INACTIVE);
        require(!reserveConfig.isPaused, Errors.RESERVE_PAUSED);
    }

    struct ValidateBorrowLocalVars {
        uint256 currentLtv;
        uint256 collateralNeededInBaseCurrency;
        uint256 userCollateralInBaseCurrency;
        uint256 userDebtInBaseCurrency;
        uint256 availableLiquidity;
        uint256 healthFactor;
        uint256 totalDebt;
        uint256 totalSupplyVariableDebt;
        uint256 reserveDecimals;
        uint256 borrowCap;
        uint256 amountInBaseCurrency;
        uint256 assetUnit;
        bool isActive;
        bool isFrozen;
        bool isPaused;
        bool borrowingEnabled;
    }

    /**
     * @notice Validates a borrow action.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param params Additional params needed for the validation
     */
    function validateBorrow(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        mapping(address => DataTypes.ERC1155ReserveData) storage erc1155ReservesData,
        DataTypes.UserERC1155ConfigurationMap storage userERC1155Config,
        DataTypes.ValidateBorrowParams memory params
    ) internal view {
        require(params.amount != 0, Errors.INVALID_AMOUNT);

        ValidateBorrowLocalVars memory vars;

        (vars.isActive, vars.isFrozen, vars.borrowingEnabled, vars.isPaused) =
            params.reserveCache.reserveConfiguration.getFlags();

        require(vars.isActive, Errors.RESERVE_INACTIVE);
        require(!vars.isPaused, Errors.RESERVE_PAUSED);
        require(!vars.isFrozen, Errors.RESERVE_FROZEN);
        require(vars.borrowingEnabled, Errors.BORROWING_NOT_ENABLED);

        require(
            params.priceOracleSentinel == address(0)
                || IPriceOracleSentinel(params.priceOracleSentinel).isBorrowAllowed(),
            Errors.PRICE_ORACLE_SENTINEL_CHECK_FAILED
        );

        vars.reserveDecimals = params.reserveCache.reserveConfiguration.getDecimals();
        vars.borrowCap = params.reserveCache.reserveConfiguration.getBorrowCap();
        unchecked {
            vars.assetUnit = 10 ** vars.reserveDecimals;
        }

        if (vars.borrowCap != 0) {
            vars.totalSupplyVariableDebt =
                params.reserveCache.currScaledVariableDebt.rayMul(params.reserveCache.nextVariableBorrowIndex);

            vars.totalDebt = vars.totalSupplyVariableDebt + params.amount;

            unchecked {
                require(vars.totalDebt <= vars.borrowCap * vars.assetUnit, Errors.BORROW_CAP_EXCEEDED);
            }
        }

        (vars.userCollateralInBaseCurrency, vars.userDebtInBaseCurrency, vars.currentLtv,, vars.healthFactor,) =
        GenericLogic.calculateUserAccountData(
            reservesData,
            reservesList,
            erc1155ReservesData,
            userERC1155Config,
            DataTypes.CalculateUserAccountDataParams({
                userConfig: params.userConfig,
                reservesCount: params.reservesCount,
                user: params.userAddress,
                oracle: params.oracle
            })
        );

        require(vars.userCollateralInBaseCurrency != 0, Errors.COLLATERAL_BALANCE_IS_ZERO);
        require(vars.currentLtv != 0, Errors.LTV_VALIDATION_FAILED);

        require(
            vars.healthFactor > HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
            Errors.HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
        );

        vars.amountInBaseCurrency = IPriceOracleGetter(params.oracle).getAssetPrice(params.asset) * params.amount;
        unchecked {
            vars.amountInBaseCurrency /= vars.assetUnit;
        }

        //add the current already borrowed amount to the amount requested to calculate the total collateral needed.
        vars.collateralNeededInBaseCurrency =
            (vars.userDebtInBaseCurrency + vars.amountInBaseCurrency).percentDiv(vars.currentLtv); //LTV is calculated in percentage

        require(
            vars.collateralNeededInBaseCurrency <= vars.userCollateralInBaseCurrency,
            Errors.COLLATERAL_CANNOT_COVER_NEW_BORROW
        );
    }

    /**
     * @notice Validates a repay action.
     * @param reserveCache The cached data of the reserve
     * @param amountSent The amount sent for the repayment. Can be an actual value or uint(-1)
     * @param onBehalfOf The address of the user msg.sender is repaying for
     * @param variableDebt The borrow balance of the user
     */
    function validateRepay(
        DataTypes.ReserveCache memory reserveCache,
        uint256 amountSent,
        address onBehalfOf,
        uint256 variableDebt
    ) internal view {
        require(amountSent != 0, Errors.INVALID_AMOUNT);
        require(
            amountSent != type(uint256).max || msg.sender == onBehalfOf, Errors.NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF
        );

        (bool isActive,,, bool isPaused) = reserveCache.reserveConfiguration.getFlags();
        require(isActive, Errors.RESERVE_INACTIVE);
        require(!isPaused, Errors.RESERVE_PAUSED);

        require(variableDebt != 0, Errors.NO_DEBT);
    }

    /**
     * @notice Validates the action of setting an asset as collateral.
     * @param reserveCache The cached data of the reserve
     * @param userBalance The balance of the user
     */
    function validateSetUseReserveAsCollateral(DataTypes.ReserveCache memory reserveCache, uint256 userBalance)
        internal
        pure
    {
        require(userBalance != 0, Errors.UNDERLYING_BALANCE_ZERO);

        (bool isActive,,, bool isPaused) = reserveCache.reserveConfiguration.getFlags();
        require(isActive, Errors.RESERVE_INACTIVE);
        require(!isPaused, Errors.RESERVE_PAUSED);
    }

    /**
     * @notice Validates a flashloan action.
     * @param reservesData The state of all the reserves
     * @param assets The assets being flash-borrowed
     * @param amounts The amounts for each asset being borrowed
     */
    function validateFlashloan(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        address[] memory assets,
        uint256[] memory amounts
    ) internal view {
        require(assets.length == amounts.length, Errors.INCONSISTENT_FLASHLOAN_PARAMS);
        for (uint256 i = 0; i < assets.length; i++) {
            validateFlashloanSimple(reservesData[assets[i]]);
        }
    }

    /**
     * @notice Validates a flashloan action.
     * @param reserve The state of the reserve
     */
    function validateFlashloanSimple(DataTypes.ReserveData storage reserve) internal view {
        DataTypes.ReserveConfigurationMap memory configuration = reserve.configuration;
        require(!configuration.getPaused(), Errors.RESERVE_PAUSED);
        require(configuration.getActive(), Errors.RESERVE_INACTIVE);
        require(configuration.getFlashLoanEnabled(), Errors.FLASHLOAN_DISABLED);
    }

    struct ValidateLiquidationCallLocalVars {
        bool collateralReserveActive;
        bool collateralReservePaused;
        bool principalReserveActive;
        bool principalReservePaused;
        bool isCollateralEnabled;
    }

    /**
     * @notice Validates the liquidation action.
     * @param userConfig The user configuration mapping
     * @param collateralReserve The reserve data of the collateral
     * @param params Additional parameters needed for the validation
     */
    function validateLiquidationCall(
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ReserveData storage collateralReserve,
        DataTypes.ValidateLiquidationCallParams memory params
    ) internal view {
        ValidateLiquidationCallLocalVars memory vars;

        (vars.collateralReserveActive,,, vars.collateralReservePaused) = collateralReserve.configuration.getFlags();

        (vars.principalReserveActive,,, vars.principalReservePaused) =
            params.debtReserveCache.reserveConfiguration.getFlags();

        require(vars.collateralReserveActive && vars.principalReserveActive, Errors.RESERVE_INACTIVE);
        require(!vars.collateralReservePaused && !vars.principalReservePaused, Errors.RESERVE_PAUSED);

        require(
            params.priceOracleSentinel == address(0)
                || params.healthFactor < MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD
                || IPriceOracleSentinel(params.priceOracleSentinel).isLiquidationAllowed(),
            Errors.PRICE_ORACLE_SENTINEL_CHECK_FAILED
        );

        require(params.healthFactor < HEALTH_FACTOR_LIQUIDATION_THRESHOLD, Errors.HEALTH_FACTOR_NOT_BELOW_THRESHOLD);

        vars.isCollateralEnabled = collateralReserve.configuration.getLiquidationThreshold() != 0
            && userConfig.isUsingAsCollateral(collateralReserve.id);

        //if collateral isn't enabled as collateral by user, it cannot be liquidated
        require(vars.isCollateralEnabled, Errors.COLLATERAL_CANNOT_BE_LIQUIDATED);
        require(params.totalDebt != 0, Errors.SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER);
    }

    struct ValidateERC1155LiquidationCallLocalVars {
        bool collateralReserveActive;
        bool collateralReservePaused;
        bool debtReserveActive;
        bool debtReservePaused;
        bool isCollateralEnabled;
    }

    function validateERC1155LiquidationCall(
        DataTypes.UserERC1155ConfigurationMap storage userERC1155Config,
        DataTypes.ERC1155ReserveData storage collateralReserve,
        DataTypes.ERC1155ReserveConfiguration memory collateralReserveConfig,
        DataTypes.ValidateERC1155LiquidationCallParams memory params
    ) internal view {
        ValidateERC1155LiquidationCallLocalVars memory vars;

        (vars.debtReserveActive,,, vars.debtReservePaused) = params.debtReserveCache.reserveConfiguration.getFlags();

        require(collateralReserveConfig.isActive && vars.debtReserveActive, Errors.RESERVE_INACTIVE);
        require(!collateralReserveConfig.isPaused && !vars.debtReservePaused, Errors.RESERVE_PAUSED);

        require(
            params.priceOracleSentinel == address(0)
                || params.healthFactor < MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD
                || IPriceOracleSentinel(params.priceOracleSentinel).isLiquidationAllowed(),
            Errors.PRICE_ORACLE_SENTINEL_CHECK_FAILED
        );

        require(params.healthFactor < HEALTH_FACTOR_LIQUIDATION_THRESHOLD, Errors.HEALTH_FACTOR_NOT_BELOW_THRESHOLD);

        vars.isCollateralEnabled = collateralReserveConfig.liquidationThreshold != 0
            && userERC1155Config.isUsingAsCollateral(params.collateralReserveAddress, params.collateralReserveTokenId);

        //if collateral isn't enabled as collateral by user, it cannot be liquidated
        require(vars.isCollateralEnabled, Errors.COLLATERAL_CANNOT_BE_LIQUIDATED);
        require(params.totalDebt != 0, Errors.SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER);
    }

    /**
     * @notice Validates the health factor of a user.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param params Additional parameters needed for the validation
     */
    function validateHealthFactor(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        mapping(address => DataTypes.ERC1155ReserveData) storage erc1155ReservesData,
        DataTypes.UserERC1155ConfigurationMap storage userERC1155Config,
        DataTypes.ValidateHealthFactorParams memory params
    ) internal view returns (uint256, bool) {
        (,,,, uint256 healthFactor, bool hasZeroLtvCollateral) = GenericLogic.calculateUserAccountData(
            reservesData,
            reservesList,
            erc1155ReservesData,
            userERC1155Config,
            DataTypes.CalculateUserAccountDataParams({
                userConfig: params.userConfig,
                reservesCount: params.reservesCount,
                user: params.user,
                oracle: params.oracle
            })
        );

        require(
            healthFactor >= HEALTH_FACTOR_LIQUIDATION_THRESHOLD, Errors.HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
        );

        return (healthFactor, hasZeroLtvCollateral);
    }

    /**
     * @notice Validates the health factor of a user and the ltv of the asset being withdrawn.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param userConfig The state of the user for the specific reserve
     * @param reserveLtv The LTV of asset for which the ltv will be validated
     * @param from The user from which the yTokens are being transferred
     * @param reservesCount The number of available reserves
     * @param oracle The price oracle
     */
    function validateHFAndLtv(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        mapping(address => DataTypes.ERC1155ReserveData) storage erc1155ReservesData,
        DataTypes.UserConfigurationMap memory userConfig,
        DataTypes.UserERC1155ConfigurationMap storage userERC1155Config,
        uint256 reserveLtv,
        address from,
        uint256 reservesCount,
        address oracle
    ) internal view {
        (, bool hasZeroLtvCollateral) = validateHealthFactor(
            reservesData,
            reservesList,
            erc1155ReservesData,
            userERC1155Config,
            DataTypes.ValidateHealthFactorParams({
                userConfig: userConfig,
                user: from,
                reservesCount: reservesCount,
                oracle: oracle
            })
        );

        require(!hasZeroLtvCollateral || reserveLtv == 0, Errors.LTV_VALIDATION_FAILED);
    }

    /**
     * @notice Validates a transfer action.
     * @param reserve The reserve object
     */
    function validateTransfer(DataTypes.ReserveData storage reserve) internal view {
        require(!reserve.configuration.getPaused(), Errors.RESERVE_PAUSED);
    }

    /**
     * @notice Validates a ERC1155 transfer action.
     * @param reserveConfig The reserve config
     */
    function validateERC1155Transfer(DataTypes.ERC1155ReserveConfiguration memory reserveConfig) internal pure {
        require(!reserveConfig.isPaused, Errors.RESERVE_PAUSED);
    }

    /**
     * @notice Validates a drop reserve action.
     * @param reservesList The addresses of all the active reserves
     * @param reserve The reserve object
     * @param asset The address of the reserve's underlying asset
     */
    function validateDropReserve(
        mapping(uint256 => address) storage reservesList,
        DataTypes.ReserveData storage reserve,
        address asset
    ) internal view {
        require(asset != address(0), Errors.ZERO_ADDRESS_NOT_VALID);
        require(reserve.id != 0 || reservesList[0] == asset, Errors.ASSET_NOT_LISTED);
        require(IERC20(reserve.variableDebtTokenAddress).totalSupply() == 0, Errors.VARIABLE_DEBT_SUPPLY_NOT_ZERO);
        require(
            IERC20(reserve.yTokenAddress).totalSupply() == 0 && reserve.accruedToTreasury == 0,
            Errors.UNDERLYING_CLAIMABLE_RIGHTS_NOT_ZERO
        );
    }

    /**
     * @notice Validates a drop ERC1155 reserve action.
     * @param reserve The reserve object
     * @param asset The address of the reserve's underlying asset
     */
    function validateDropERC1155Reserve(DataTypes.ERC1155ReserveData storage reserve, address asset) internal view {
        // For non-existent reserve, asset will be zero, so this actually checks if the reserve exists too
        require(asset != address(0), Errors.ZERO_ADDRESS_NOT_VALID);
        require(INToken(reserve.nTokenAddress).totalSupply() == 0, Errors.UNDERLYING_CLAIMABLE_RIGHTS_NOT_ZERO);
    }

    /**
     * @notice Validates the action of activating the asset as collateral.
     * @dev Only possible if the asset has non-zero LTV
     * @param reserveConfig The reserve configuration
     * @return True if the asset can be activated as collateral, false otherwise
     */
    function validateUseAsCollateral(DataTypes.ReserveConfigurationMap memory reserveConfig)
        internal
        pure
        returns (bool)
    {
        return reserveConfig.getLtv() != 0;
    }

    /**
     * @notice Validates the action of activating the asset as collateral.
     * @dev Only possible if the asset has non-zero LTV
     * @param reserveConfig The reserve configuration
     * @return True if the asset can be activated as collateral, false otherwise
     */
    function validateUseERC1155AsCollateral(
        DataTypes.ERC1155ReserveConfiguration memory reserveConfig,
        DataTypes.UserERC1155ConfigurationMap storage userERC1155Config,
        uint256 maxERC1155CollateralReserves
    ) internal view returns (bool) {
        if (maxERC1155CollateralReserves == 0) {
            return false;
        }
        if (userERC1155Config.getUsedReservesCount() >= maxERC1155CollateralReserves) {
            return false;
        }
        return reserveConfig.ltv != 0;
    }
}
