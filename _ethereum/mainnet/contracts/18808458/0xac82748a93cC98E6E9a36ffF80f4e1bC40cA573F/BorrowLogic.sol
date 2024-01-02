// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import "./SafeERC20.sol";
import "./SafeCast.sol";
import "./IERC20.sol";
import "./IVariableDebtToken.sol";
import "./IYToken.sol";
import "./IPool.sol";
import "./UserConfiguration.sol";
import "./ReserveConfiguration.sol";
import "./Helpers.sol";
import "./DataTypes.sol";
import "./ValidationLogic.sol";
import "./ReserveLogic.sol";

/**
 * @title BorrowLogic library
 *
 * @notice Implements the base logic for all the actions related to borrowing
 */
library BorrowLogic {
    using ReserveLogic for DataTypes.ReserveCache;
    using ReserveLogic for DataTypes.ReserveData;
    using SafeERC20 for IERC20;
    using UserConfiguration for DataTypes.UserConfigurationMap;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using SafeCast for uint256;

    /**
     * @notice Implements the borrow feature. Borrowing allows users that provided collateral to draw liquidity from the
     * YLDR protocol proportionally to their collateralization power. For isolated positions, it also increases the
     * isolated debt.
     * @dev  Emits the `Borrow()` event
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
     * @param params The additional parameters needed to execute the borrow function
     */
    function executeBorrow(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        mapping(address => DataTypes.ERC1155ReserveData) storage erc1155ReservesData,
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.UserERC1155ConfigurationMap storage userERC1155Config,
        DataTypes.ExecuteBorrowParams memory params
    ) public {
        DataTypes.ReserveData storage reserve = reservesData[params.asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();

        reserve.updateState(reserveCache);

        ValidationLogic.validateBorrow(
            reservesData,
            reservesList,
            erc1155ReservesData,
            userERC1155Config,
            DataTypes.ValidateBorrowParams({
                reserveCache: reserveCache,
                userConfig: userConfig,
                asset: params.asset,
                userAddress: params.onBehalfOf,
                amount: params.amount,
                reservesCount: params.reservesCount,
                oracle: params.oracle,
                priceOracleSentinel: params.priceOracleSentinel
            })
        );

        bool isFirstBorrowing = false;

        (isFirstBorrowing, reserveCache.nextScaledVariableDebt) = IVariableDebtToken(
            reserveCache.variableDebtTokenAddress
        ).mint(params.user, params.onBehalfOf, params.amount, reserveCache.nextVariableBorrowIndex);

        if (isFirstBorrowing) {
            userConfig.setBorrowing(reserve.id, true);
        }

        reserve.updateInterestRates(reserveCache, params.asset, 0, params.releaseUnderlying ? params.amount : 0);

        if (params.releaseUnderlying) {
            IYToken(reserveCache.yTokenAddress).transferUnderlyingTo(params.user, params.amount);
        }

        emit IPool.Borrow(
            params.asset,
            params.user,
            params.onBehalfOf,
            params.amount,
            reserve.currentVariableBorrowRate,
            params.referralCode
        );
    }

    /**
     * @notice Implements the repay feature. Repaying transfers the underlying back to the yToken and clears the
     * equivalent amount of debt for the user by burning the corresponding debt token. For isolated positions, it also
     * reduces the isolated debt.
     * @dev  Emits the `Repay()` event
     * @param reservesData The state of all the reserves
     * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
     * @param params The additional parameters needed to execute the repay function
     * @return The actual amount being repaid
     */
    function executeRepay(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ExecuteRepayParams memory params
    ) external returns (uint256) {
        DataTypes.ReserveData storage reserve = reservesData[params.asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();
        reserve.updateState(reserveCache);

        uint256 variableDebt = Helpers.getUserCurrentDebt(params.onBehalfOf, reserveCache);

        ValidationLogic.validateRepay(reserveCache, params.amount, params.onBehalfOf, variableDebt);

        uint256 paybackAmount = variableDebt;

        // Allows a user to repay with yTokens without leaving dust from interest.
        if (params.useYTokens && params.amount == type(uint256).max) {
            params.amount = IYToken(reserveCache.yTokenAddress).balanceOf(msg.sender);
        }

        if (params.amount < paybackAmount) {
            paybackAmount = params.amount;
        }

        reserveCache.nextScaledVariableDebt = IVariableDebtToken(reserveCache.variableDebtTokenAddress).burn(
            params.onBehalfOf, paybackAmount, reserveCache.nextVariableBorrowIndex
        );

        reserve.updateInterestRates(reserveCache, params.asset, params.useYTokens ? 0 : paybackAmount, 0);

        if (variableDebt == paybackAmount) {
            userConfig.setBorrowing(reserve.id, false);
        }

        if (params.useYTokens) {
            IYToken(reserveCache.yTokenAddress).burn(
                msg.sender, reserveCache.yTokenAddress, paybackAmount, reserveCache.nextLiquidityIndex
            );
        } else {
            IERC20(params.asset).safeTransferFrom(msg.sender, reserveCache.yTokenAddress, paybackAmount);
            IYToken(reserveCache.yTokenAddress).handleRepayment(msg.sender, params.onBehalfOf, paybackAmount);
        }

        emit IPool.Repay(params.asset, params.onBehalfOf, msg.sender, paybackAmount, params.useYTokens);

        return paybackAmount;
    }
}
