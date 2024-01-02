// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import "./IERC20.sol";
import "./IERC1155.sol";
import "./IERC1155Supply.sol";
import "./SafeERC20.sol";
import "./PercentageMath.sol";
import "./WadRayMath.sol";
import "./Helpers.sol";
import "./DataTypes.sol";
import "./ReserveLogic.sol";
import "./ERC1155ReserveLogic.sol";
import "./ValidationLogic.sol";
import "./GenericLogic.sol";
import "./UserConfiguration.sol";
import "./UserERC1155Configuration.sol";
import "./ReserveConfiguration.sol";
import "./IYToken.sol";
import "./INToken.sol";
import "./IPool.sol";
import "./IVariableDebtToken.sol";
import "./IPriceOracleGetter.sol";

/**
 * @title LiquidationLogic library
 *
 * @notice Implements actions involving management of collateral in the protocol, the main one being the liquidations
 */
library LiquidationLogic {
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using ReserveLogic for DataTypes.ReserveCache;
    using ReserveLogic for DataTypes.ReserveData;
    using ERC1155ReserveLogic for DataTypes.ERC1155ReserveData;
    using UserConfiguration for DataTypes.UserConfigurationMap;
    using UserERC1155Configuration for DataTypes.UserERC1155ConfigurationMap;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using SafeERC20 for IERC20;

    /**
     * @dev Default percentage of borrower's debt to be repaid in a liquidation.
     * @dev Percentage applied when the users health factor is above `CLOSE_FACTOR_HF_THRESHOLD`
     * Expressed in bps, a value of 0.5e4 results in 50.00%
     */
    uint256 internal constant DEFAULT_LIQUIDATION_CLOSE_FACTOR = 0.5e4;

    /**
     * @dev Maximum percentage of borrower's debt to be repaid in a liquidation
     * @dev Percentage applied when the users health factor is below `CLOSE_FACTOR_HF_THRESHOLD`
     * Expressed in bps, a value of 1e4 results in 100.00%
     */
    uint256 public constant MAX_LIQUIDATION_CLOSE_FACTOR = 1e4;

    /**
     * @dev This constant represents below which health factor value it is possible to liquidate
     * an amount of debt corresponding to `MAX_LIQUIDATION_CLOSE_FACTOR`.
     * A value of 0.95e18 results in 0.95
     */
    uint256 public constant CLOSE_FACTOR_HF_THRESHOLD = 0.95e18;

    struct LiquidationCallLocalVars {
        uint256 userCollateralBalance;
        uint256 userVariableDebt;
        uint256 userTotalDebt;
        uint256 actualDebtToLiquidate;
        uint256 actualCollateralToLiquidate;
        uint256 liquidationBonus;
        uint256 healthFactor;
        uint256 liquidationProtocolFeeAmount;
        IYToken collateralYToken;
        DataTypes.ReserveCache debtReserveCache;
    }

    /**
     * @notice Function to liquidate a position if its Health Factor drops below 1. The caller (liquidator)
     * covers `debtToCover` amount of debt of the user getting liquidated, and receives
     * a proportional amount of the `collateralAsset` plus a bonus to cover market risk
     * @dev Emits the `LiquidationCall()` event
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param usersConfig The users configuration mapping that track the supplied/borrowed assets
     * @param params The additional parameters needed to execute the liquidation function
     */
    function executeLiquidationCall(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        mapping(address => DataTypes.ERC1155ReserveData) storage erc1155ReservesData,
        mapping(address => DataTypes.UserConfigurationMap) storage usersConfig,
        mapping(address => DataTypes.UserERC1155ConfigurationMap) storage usersERC1155Config,
        DataTypes.ExecuteLiquidationCallParams memory params
    ) external {
        LiquidationCallLocalVars memory vars;

        DataTypes.ReserveData storage collateralReserve = reservesData[params.collateralAsset];
        DataTypes.ReserveData storage debtReserve = reservesData[params.debtAsset];
        DataTypes.UserConfigurationMap storage userConfig = usersConfig[params.user];
        DataTypes.UserERC1155ConfigurationMap storage userERC1155Config = usersERC1155Config[params.user];
        vars.debtReserveCache = debtReserve.cache();
        debtReserve.updateState(vars.debtReserveCache);

        (,,,, vars.healthFactor,) = GenericLogic.calculateUserAccountData(
            reservesData,
            reservesList,
            erc1155ReservesData,
            userERC1155Config,
            DataTypes.CalculateUserAccountDataParams({
                userConfig: userConfig,
                reservesCount: params.reservesCount,
                user: params.user,
                oracle: params.priceOracle
            })
        );

        (vars.userVariableDebt, vars.userTotalDebt, vars.actualDebtToLiquidate) =
            _calculateDebt(vars.debtReserveCache, params.user, params.debtToCover, vars.healthFactor);

        ValidationLogic.validateLiquidationCall(
            userConfig,
            collateralReserve,
            DataTypes.ValidateLiquidationCallParams({
                debtReserveCache: vars.debtReserveCache,
                totalDebt: vars.userTotalDebt,
                healthFactor: vars.healthFactor,
                priceOracleSentinel: params.priceOracleSentinel
            })
        );

        (vars.collateralYToken, vars.liquidationBonus) = _getConfigurationData(collateralReserve);

        vars.userCollateralBalance = vars.collateralYToken.balanceOf(params.user);

        (vars.actualCollateralToLiquidate, vars.actualDebtToLiquidate, vars.liquidationProtocolFeeAmount) =
        _calculateAvailableCollateralToLiquidate(
            collateralReserve,
            vars.debtReserveCache,
            params.collateralAsset,
            params.debtAsset,
            vars.actualDebtToLiquidate,
            vars.userCollateralBalance,
            vars.liquidationBonus,
            IPriceOracleGetter(params.priceOracle)
        );

        if (vars.userTotalDebt == vars.actualDebtToLiquidate) {
            userConfig.setBorrowing(debtReserve.id, false);
        }

        // If the collateral being liquidated is equal to the user balance,
        // we set the currency as not being used as collateral anymore
        if (vars.actualCollateralToLiquidate + vars.liquidationProtocolFeeAmount == vars.userCollateralBalance) {
            userConfig.setUsingAsCollateral(collateralReserve.id, false);
            emit IPool.ReserveUsedAsCollateralDisabled(params.collateralAsset, params.user);
        }

        // This mutates vars.debtReserveCache
        _burnDebtTokens(params.user, vars.userVariableDebt, vars.actualDebtToLiquidate, vars.debtReserveCache);

        debtReserve.updateInterestRates(vars.debtReserveCache, params.debtAsset, vars.actualDebtToLiquidate, 0);

        if (params.receiveYToken) {
            _liquidateYTokens(usersConfig, collateralReserve, params, vars);
        } else {
            _burnCollateralYTokens(collateralReserve, params, vars);
        }

        // Transfer fee to treasury if it is non-zero
        if (vars.liquidationProtocolFeeAmount != 0) {
            uint256 liquidityIndex = collateralReserve.getNormalizedIncome();
            uint256 scaledDownLiquidationProtocolFee = vars.liquidationProtocolFeeAmount.rayDiv(liquidityIndex);
            uint256 scaledDownUserBalance = vars.collateralYToken.scaledBalanceOf(params.user);
            // To avoid trying to send more yTokens than available on balance, due to 1 wei imprecision
            if (scaledDownLiquidationProtocolFee > scaledDownUserBalance) {
                vars.liquidationProtocolFeeAmount = scaledDownUserBalance.rayMul(liquidityIndex);
            }
            vars.collateralYToken.transferOnLiquidation(
                params.user, vars.collateralYToken.RESERVE_TREASURY_ADDRESS(), vars.liquidationProtocolFeeAmount
            );
        }

        // Transfers the debt asset being repaid to the yToken, where the liquidity is kept
        IERC20(params.debtAsset).safeTransferFrom(
            msg.sender, vars.debtReserveCache.yTokenAddress, vars.actualDebtToLiquidate
        );

        IYToken(vars.debtReserveCache.yTokenAddress).handleRepayment(
            msg.sender, params.user, vars.actualDebtToLiquidate
        );

        emit IPool.LiquidationCall(
            params.collateralAsset,
            params.debtAsset,
            params.user,
            vars.actualDebtToLiquidate,
            vars.actualCollateralToLiquidate,
            msg.sender,
            params.receiveYToken
        );
    }

    struct ERC1155LiquidationCallLocalVars {
        uint256 userCollateralBalance;
        uint256 userVariableDebt;
        uint256 userTotalDebt;
        uint256 actualDebtToLiquidate;
        uint256 actualCollateralToLiquidate;
        uint256 liquidationBonus;
        uint256 healthFactor;
        uint256 liquidationProtocolFeeAmount;
        INToken collateralNToken;
        DataTypes.ERC1155ReserveConfiguration collateralReserveConfig;
        DataTypes.ReserveCache debtReserveCache;
    }

    /**
     * @notice Function to liquidate a position if its Health Factor drops below 1. The caller (liquidator)
     * covers `debtToCover` amount of debt of the user getting liquidated, and receives
     * a proportional amount of the `collateralAsset` plus a bonus to cover market risk
     * @dev Emits the `LiquidationCall()` event
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param usersConfig The users configuration mapping that track the supplied/borrowed assets
     * @param params The additional parameters needed to execute the liquidation function
     */
    function executeERC1155LiquidationCall(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        mapping(address => DataTypes.ERC1155ReserveData) storage erc1155ReservesData,
        mapping(address => DataTypes.UserConfigurationMap) storage usersConfig,
        mapping(address => DataTypes.UserERC1155ConfigurationMap) storage usersERC1155Config,
        DataTypes.ExecuteERC1155LiquidationCallParams memory params
    ) external {
        ERC1155LiquidationCallLocalVars memory vars;

        DataTypes.ERC1155ReserveData storage collateralReserve = erc1155ReservesData[params.collateralAsset];
        DataTypes.ReserveData storage debtReserve = reservesData[params.debtAsset];
        DataTypes.UserConfigurationMap storage userConfig = usersConfig[params.user];
        DataTypes.UserERC1155ConfigurationMap storage userERC1155Config = usersERC1155Config[params.user];

        vars.collateralReserveConfig = collateralReserve.getConfiguration(params.collateralTokenId);
        vars.debtReserveCache = debtReserve.cache();

        debtReserve.updateState(vars.debtReserveCache);

        (,,,, vars.healthFactor,) = GenericLogic.calculateUserAccountData(
            reservesData,
            reservesList,
            erc1155ReservesData,
            userERC1155Config,
            DataTypes.CalculateUserAccountDataParams({
                userConfig: userConfig,
                reservesCount: params.reservesCount,
                user: params.user,
                oracle: params.priceOracle
            })
        );

        (vars.userVariableDebt, vars.userTotalDebt, vars.actualDebtToLiquidate) =
            _calculateDebt(vars.debtReserveCache, params.user, params.debtToCover, vars.healthFactor);

        ValidationLogic.validateERC1155LiquidationCall(
            userERC1155Config,
            collateralReserve,
            collateralReserve.getConfiguration(params.collateralTokenId),
            DataTypes.ValidateERC1155LiquidationCallParams({
                collateralReserveAddress: params.collateralAsset,
                collateralReserveTokenId: params.collateralTokenId,
                debtReserveCache: vars.debtReserveCache,
                totalDebt: vars.userTotalDebt,
                healthFactor: vars.healthFactor,
                priceOracleSentinel: params.priceOracleSentinel
            })
        );

        vars.collateralNToken = INToken(collateralReserve.nTokenAddress);
        vars.liquidationBonus = vars.collateralReserveConfig.liquidationBonus;

        vars.userCollateralBalance = vars.collateralNToken.balanceOf(params.user, params.collateralTokenId);

        (vars.actualCollateralToLiquidate, vars.actualDebtToLiquidate, vars.liquidationProtocolFeeAmount) =
        _calculateAvailableERC1155CollateralToLiquidate(
            collateralReserve,
            vars.debtReserveCache,
            params.collateralAsset,
            params.collateralTokenId,
            params.debtAsset,
            vars.actualDebtToLiquidate,
            vars.userCollateralBalance,
            vars.liquidationBonus,
            IPriceOracleGetter(params.priceOracle)
        );

        if (vars.userTotalDebt == vars.actualDebtToLiquidate) {
            userConfig.setBorrowing(debtReserve.id, false);
        }

        // If the collateral being liquidated is equal to the user balance,
        // we set the currency as not being used as collateral anymore
        if (vars.actualCollateralToLiquidate + vars.liquidationProtocolFeeAmount == vars.userCollateralBalance) {
            userERC1155Config.setUsingAsCollateral(params.collateralAsset, params.collateralTokenId, false);
            emit IPool.ERC1155ReserveUsedAsCollateralDisabled(
                params.collateralAsset, params.collateralTokenId, params.user
            );
        }

        // This mutates vars.debtReserveCache
        _burnDebtTokens(params.user, vars.userVariableDebt, vars.actualDebtToLiquidate, vars.debtReserveCache);

        debtReserve.updateInterestRates(vars.debtReserveCache, params.debtAsset, vars.actualDebtToLiquidate, 0);

        if (params.receiveNToken) {
            _liquidateNTokens(usersERC1155Config, params, vars);
        } else {
            vars.collateralNToken.burn(
                params.user, msg.sender, params.collateralTokenId, vars.actualCollateralToLiquidate
            );
        }

        // Transfer fee to treasury if it is non-zero
        if (vars.liquidationProtocolFeeAmount != 0) {
            vars.collateralNToken.safeTransferFromOnLiquidation(
                params.user,
                vars.collateralNToken.RESERVE_TREASURY_ADDRESS(),
                params.collateralTokenId,
                vars.liquidationProtocolFeeAmount,
                bytes("")
            );
        }

        // Transfers the debt asset being repaid to the yToken, where the liquidity is kept
        IERC20(params.debtAsset).safeTransferFrom(
            msg.sender, vars.debtReserveCache.yTokenAddress, vars.actualDebtToLiquidate
        );

        emit IPool.ERC1155LiquidationCall(
            params.collateralAsset,
            params.collateralTokenId,
            params.debtAsset,
            params.user,
            vars.actualDebtToLiquidate,
            vars.actualCollateralToLiquidate,
            msg.sender,
            params.receiveNToken
        );
    }

    /**
     * @notice Burns the collateral yTokens and transfers the underlying to the liquidator.
     * @dev   The function also updates the state and the interest rate of the collateral reserve.
     * @param collateralReserve The data of the collateral reserve
     * @param params The additional parameters needed to execute the liquidation function
     * @param vars The executeLiquidationCall() function local vars
     */
    function _burnCollateralYTokens(
        DataTypes.ReserveData storage collateralReserve,
        DataTypes.ExecuteLiquidationCallParams memory params,
        LiquidationCallLocalVars memory vars
    ) internal {
        DataTypes.ReserveCache memory collateralReserveCache = collateralReserve.cache();
        collateralReserve.updateState(collateralReserveCache);
        collateralReserve.updateInterestRates(
            collateralReserveCache, params.collateralAsset, 0, vars.actualCollateralToLiquidate
        );

        // Burn the equivalent amount of yToken, sending the underlying to the liquidator
        vars.collateralYToken.burn(
            params.user, msg.sender, vars.actualCollateralToLiquidate, collateralReserveCache.nextLiquidityIndex
        );
    }

    /**
     * @notice Liquidates the user yTokens by transferring them to the liquidator.
     * @dev   The function also checks the state of the liquidator and activates the yToken as collateral
     *        as in standard transfers if the isolation mode constraints are respected.
     * @param usersConfig The users configuration mapping that track the supplied/borrowed assets
     * @param collateralReserve The data of the collateral reserve
     * @param params The additional parameters needed to execute the liquidation function
     * @param vars The executeLiquidationCall() function local vars
     */
    function _liquidateYTokens(
        mapping(address => DataTypes.UserConfigurationMap) storage usersConfig,
        DataTypes.ReserveData storage collateralReserve,
        DataTypes.ExecuteLiquidationCallParams memory params,
        LiquidationCallLocalVars memory vars
    ) internal {
        uint256 liquidatorPreviousYTokenBalance = IERC20(vars.collateralYToken).balanceOf(msg.sender);
        vars.collateralYToken.transferOnLiquidation(params.user, msg.sender, vars.actualCollateralToLiquidate);

        if (liquidatorPreviousYTokenBalance == 0) {
            DataTypes.UserConfigurationMap storage liquidatorConfig = usersConfig[msg.sender];
            if (ValidationLogic.validateUseAsCollateral(collateralReserve.configuration)) {
                liquidatorConfig.setUsingAsCollateral(collateralReserve.id, true);
                emit IPool.ReserveUsedAsCollateralEnabled(params.collateralAsset, msg.sender);
            }
        }
    }

    /**
     * @notice Liquidates the user nTokens by transferring them to the liquidator.
     * @dev   The function also checks the state of the liquidator and activates the nToken as collateral
     *        as in standard transfers if the isolation mode constraints are respected.
     * @param usersERC1155Config The users configuration mapping that track the supplied/borrowed ERC1155 assets
     * @param params The additional parameters needed to execute the liquidation function
     * @param vars The executeLiquidationCall() function local vars
     */
    function _liquidateNTokens(
        mapping(address => DataTypes.UserERC1155ConfigurationMap) storage usersERC1155Config,
        DataTypes.ExecuteERC1155LiquidationCallParams memory params,
        ERC1155LiquidationCallLocalVars memory vars
    ) internal {
        uint256 liquidatorPreviousNTokenBalance = vars.collateralNToken.balanceOf(msg.sender, params.collateralTokenId);
        vars.collateralNToken.safeTransferFromOnLiquidation(
            params.user, msg.sender, params.collateralTokenId, vars.actualCollateralToLiquidate, bytes("")
        );

        if (liquidatorPreviousNTokenBalance == 0) {
            DataTypes.UserERC1155ConfigurationMap storage liquidatorConfig = usersERC1155Config[msg.sender];
            if (
                ValidationLogic.validateUseERC1155AsCollateral(
                    vars.collateralReserveConfig, liquidatorConfig, params.maxERC1155CollateralReserves
                )
            ) {
                liquidatorConfig.setUsingAsCollateral(params.collateralAsset, params.collateralTokenId, true);
                emit IPool.ERC1155ReserveUsedAsCollateralEnabled(
                    params.collateralAsset, params.collateralTokenId, msg.sender
                );
            }
        }
    }

    /**
     * @notice Burns the debt tokens of the user up to the amount being repaid by the liquidator.
     * @dev The function alters the `debtReserveCache` state  to update the debt related data.
     * @param user User whom tokens are being burnt
     * @param debtReserveCache state of debtReserve
     */
    function _burnDebtTokens(
        address user,
        uint256 userVariableDebt,
        uint256 debtToLiquidate,
        DataTypes.ReserveCache memory debtReserveCache
    ) internal {
        if (userVariableDebt >= debtToLiquidate) {
            debtReserveCache.nextScaledVariableDebt = IVariableDebtToken(debtReserveCache.variableDebtTokenAddress).burn(
                user, debtToLiquidate, debtReserveCache.nextVariableBorrowIndex
            );
        } else if (userVariableDebt != 0) {
            debtReserveCache.nextScaledVariableDebt = IVariableDebtToken(debtReserveCache.variableDebtTokenAddress).burn(
                user, userVariableDebt, debtReserveCache.nextVariableBorrowIndex
            );
        }
    }

    /**
     * @notice Calculates the total debt of the user and the actual amount to liquidate depending on the health factor
     * and corresponding close factor.
     * @dev If the Health Factor is below CLOSE_FACTOR_HF_THRESHOLD, the close factor is increased to MAX_LIQUIDATION_CLOSE_FACTOR
     * @param debtReserveCache The reserve cache data object of the debt reserve
     * @param user Use for which the debt will be covered
     * @param debtToCover provided amount of debt to be covered
     * @param healthFactor The health factor of the position
     * @return The variable debt of the user
     * @return The total debt of the user
     * @return The actual debt to liquidate as a function of the closeFactor
     */
    function _calculateDebt(
        DataTypes.ReserveCache memory debtReserveCache,
        address user,
        uint256 debtToCover,
        uint256 healthFactor
    ) internal view returns (uint256, uint256, uint256) {
        uint256 userVariableDebt = Helpers.getUserCurrentDebt(user, debtReserveCache);

        uint256 userTotalDebt = userVariableDebt;

        uint256 closeFactor =
            healthFactor > CLOSE_FACTOR_HF_THRESHOLD ? DEFAULT_LIQUIDATION_CLOSE_FACTOR : MAX_LIQUIDATION_CLOSE_FACTOR;

        uint256 maxLiquidatableDebt = userTotalDebt.percentMul(closeFactor);

        uint256 actualDebtToLiquidate = debtToCover > maxLiquidatableDebt ? maxLiquidatableDebt : debtToCover;

        return (userVariableDebt, userTotalDebt, actualDebtToLiquidate);
    }

    /**
     * @notice Returns the configuration data for the debt and the collateral reserves.
     * @param collateralReserve The data of the collateral reserve
     * @return The collateral yToken
     * @return The liquidation bonus to apply to the collateral
     */
    function _getConfigurationData(DataTypes.ReserveData storage collateralReserve)
        internal
        view
        returns (IYToken, uint256)
    {
        IYToken collateralYToken = IYToken(collateralReserve.yTokenAddress);
        uint256 liquidationBonus = collateralReserve.configuration.getLiquidationBonus();

        return (collateralYToken, liquidationBonus);
    }

    struct AvailableCollateralToLiquidateLocalVars {
        uint256 collateralPrice;
        uint256 debtAssetPrice;
        uint256 maxCollateralToLiquidate;
        uint256 baseCollateral;
        uint256 bonusCollateral;
        uint256 debtAssetDecimals;
        uint256 collateralDecimals;
        uint256 collateralAssetUnit;
        uint256 debtAssetUnit;
        uint256 collateralAmount;
        uint256 debtAmountNeeded;
        uint256 liquidationProtocolFeePercentage;
        uint256 liquidationProtocolFee;
    }

    /**
     * @notice Calculates how much of a specific collateral can be liquidated, given
     * a certain amount of debt asset.
     * @dev This function needs to be called after all the checks to validate the liquidation have been performed,
     *   otherwise it might fail.
     * @param collateralReserve The data of the collateral reserve
     * @param debtReserveCache The cached data of the debt reserve
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param userCollateralBalance The collateral balance for the specific `collateralAsset` of the user being liquidated
     * @param liquidationBonus The collateral bonus percentage to receive as result of the liquidation
     * @return The maximum amount that is possible to liquidate given all the liquidation constraints (user balance, close factor)
     * @return The amount to repay with the liquidation
     * @return The fee taken from the liquidation bonus amount to be paid to the protocol
     */
    function _calculateAvailableCollateralToLiquidate(
        DataTypes.ReserveData storage collateralReserve,
        DataTypes.ReserveCache memory debtReserveCache,
        address collateralAsset,
        address debtAsset,
        uint256 debtToCover,
        uint256 userCollateralBalance,
        uint256 liquidationBonus,
        IPriceOracleGetter oracle
    ) internal view returns (uint256, uint256, uint256) {
        AvailableCollateralToLiquidateLocalVars memory vars;

        vars.collateralPrice = oracle.getAssetPrice(collateralAsset);
        vars.debtAssetPrice = oracle.getAssetPrice(debtAsset);

        vars.collateralDecimals = collateralReserve.configuration.getDecimals();
        vars.debtAssetDecimals = debtReserveCache.reserveConfiguration.getDecimals();

        unchecked {
            vars.collateralAssetUnit = 10 ** vars.collateralDecimals;
            vars.debtAssetUnit = 10 ** vars.debtAssetDecimals;
        }

        vars.liquidationProtocolFeePercentage = collateralReserve.configuration.getLiquidationProtocolFee();

        // This is the base collateral to liquidate based on the given debt to cover
        vars.baseCollateral = ((vars.debtAssetPrice * debtToCover * vars.collateralAssetUnit))
            / (vars.collateralPrice * vars.debtAssetUnit);

        vars.maxCollateralToLiquidate = vars.baseCollateral.percentMul(liquidationBonus);

        if (vars.maxCollateralToLiquidate > userCollateralBalance) {
            vars.collateralAmount = userCollateralBalance;
            vars.debtAmountNeeded = (
                (vars.collateralPrice * vars.collateralAmount * vars.debtAssetUnit)
                    / (vars.debtAssetPrice * vars.collateralAssetUnit)
            ).percentDiv(liquidationBonus);
        } else {
            vars.collateralAmount = vars.maxCollateralToLiquidate;
            vars.debtAmountNeeded = debtToCover;
        }

        if (vars.liquidationProtocolFeePercentage != 0) {
            vars.bonusCollateral = vars.collateralAmount - vars.collateralAmount.percentDiv(liquidationBonus);

            vars.liquidationProtocolFee = vars.bonusCollateral.percentMul(vars.liquidationProtocolFeePercentage);

            return (
                vars.collateralAmount - vars.liquidationProtocolFee, vars.debtAmountNeeded, vars.liquidationProtocolFee
            );
        } else {
            return (vars.collateralAmount, vars.debtAmountNeeded, 0);
        }
    }

    struct AvailableERC1155CollateralToLiquidateLocalVars {
        uint256 collateralPrice;
        uint256 debtAssetPrice;
        uint256 maxCollateralToLiquidate;
        uint256 baseCollateral;
        uint256 bonusCollateral;
        uint256 collateralTotalSupply;
        uint256 debtAssetDecimals;
        uint256 debtAssetUnit;
        uint256 collateralAmount;
        uint256 debtAmountNeeded;
        uint256 liquidationProtocolFeePercentage;
        uint256 liquidationProtocolFee;
    }

    /**
     * @notice Calculates how much of a specific collateral can be liquidated, given
     * a certain amount of debt asset.
     * @dev This function needs to be called after all the checks to validate the liquidation have been performed,
     *   otherwise it might fail.
     * @param collateralReserve The data of the collateral reserve
     * @param debtReserveCache The cached data of the debt reserve
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param userCollateralBalance The collateral balance for the specific `collateralAsset` of the user being liquidated
     * @param liquidationBonus The collateral bonus percentage to receive as result of the liquidation
     * @return The maximum amount that is possible to liquidate given all the liquidation constraints (user balance, close factor)
     * @return The amount to repay with the liquidation
     * @return The fee taken from the liquidation bonus amount to be paid to the protocol
     */
    function _calculateAvailableERC1155CollateralToLiquidate(
        DataTypes.ERC1155ReserveData storage collateralReserve,
        DataTypes.ReserveCache memory debtReserveCache,
        address collateralAsset,
        uint256 collateralTokenId,
        address debtAsset,
        uint256 debtToCover,
        uint256 userCollateralBalance,
        uint256 liquidationBonus,
        IPriceOracleGetter oracle
    ) internal view returns (uint256, uint256, uint256) {
        AvailableERC1155CollateralToLiquidateLocalVars memory vars;

        vars.collateralPrice = oracle.getERC1155AssetPrice(collateralAsset, collateralTokenId);
        vars.collateralTotalSupply = IERC1155Supply(collateralAsset).totalSupply(collateralTokenId);

        vars.debtAssetPrice = oracle.getAssetPrice(debtAsset);

        vars.debtAssetDecimals = debtReserveCache.reserveConfiguration.getDecimals();

        unchecked {
            vars.debtAssetUnit = 10 ** vars.debtAssetDecimals;
        }

        vars.liquidationProtocolFeePercentage = collateralReserve.liquidationProtocolFee;

        // This is the base collateral to liquidate based on the given debt to cover
        vars.baseCollateral = ((vars.debtAssetPrice * debtToCover * vars.collateralTotalSupply))
            / (vars.collateralPrice * vars.debtAssetUnit);

        vars.maxCollateralToLiquidate = vars.baseCollateral.percentMul(liquidationBonus);

        if (vars.maxCollateralToLiquidate > userCollateralBalance) {
            vars.collateralAmount = userCollateralBalance;
            vars.debtAmountNeeded = (
                (vars.collateralPrice * vars.collateralAmount * vars.debtAssetUnit)
                    / (vars.debtAssetPrice * vars.collateralTotalSupply)
            ).percentDiv(liquidationBonus);
        } else {
            vars.collateralAmount = vars.maxCollateralToLiquidate;
            vars.debtAmountNeeded = debtToCover;
        }

        if (vars.liquidationProtocolFeePercentage != 0) {
            vars.bonusCollateral = vars.collateralAmount - vars.collateralAmount.percentDiv(liquidationBonus);

            vars.liquidationProtocolFee = vars.bonusCollateral.percentMul(vars.liquidationProtocolFeePercentage);

            return (
                vars.collateralAmount - vars.liquidationProtocolFee, vars.debtAmountNeeded, vars.liquidationProtocolFee
            );
        } else {
            return (vars.collateralAmount, vars.debtAmountNeeded, 0);
        }
    }
}
