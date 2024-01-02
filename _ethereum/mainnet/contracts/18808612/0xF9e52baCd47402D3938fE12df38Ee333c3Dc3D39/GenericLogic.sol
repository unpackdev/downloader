// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import "./IERC20.sol";
import "./IERC1155Supply.sol";
import "./IScaledBalanceToken.sol";
import "./IPriceOracleGetter.sol";
import "./INToken.sol";
import "./ReserveConfiguration.sol";
import "./ERC1155ReserveLogic.sol";
import "./UserConfiguration.sol";
import "./UserERC1155Configuration.sol";
import "./PercentageMath.sol";
import "./WadRayMath.sol";
import "./DataTypes.sol";
import "./ReserveLogic.sol";

/**
 * @title GenericLogic library
 *
 * @notice Implements protocol-level logic to calculate and validate the state of a user
 */
library GenericLogic {
    using ReserveLogic for DataTypes.ReserveData;
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;
    using UserERC1155Configuration for DataTypes.UserERC1155ConfigurationMap;
    using ERC1155ReserveLogic for DataTypes.ERC1155ReserveData;

    struct CalculateUserAccountDataVars {
        uint256 assetPrice;
        uint256 assetUnit;
        uint256 userBalanceInBaseCurrency;
        uint256 decimals;
        uint256 ltv;
        uint256 liquidationThreshold;
        uint256 i;
        uint256 healthFactor;
        uint256 totalCollateralInBaseCurrency;
        uint256 totalDebtInBaseCurrency;
        uint256 avgLtv;
        uint256 avgLiquidationThreshold;
        address currentReserveAddress;
        uint256 currentReserveTokenId;
        bool hasZeroLtvCollateral;
        DataTypes.ERC1155ReserveConfiguration currentReserveConfig;
    }

    /**
     * @notice Calculates the user data across the reserves.
     * @dev It includes the total liquidity/collateral/borrow balances in the base currency used by the price feed,
     * the average Loan To Value, the average Liquidation Ratio, and the Health factor.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param params Additional parameters needed for the calculation
     * @return The total collateral of the user in the base currency used by the price feed
     * @return The total debt of the user in the base currency used by the price feed
     * @return The average ltv of the user
     * @return The average liquidation threshold of the user
     * @return The health factor of the user
     * @return True if the ltv is zero, false otherwise
     */
    function calculateUserAccountData(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        mapping(address => DataTypes.ERC1155ReserveData) storage erc1155ReservesData,
        DataTypes.UserERC1155ConfigurationMap storage userERC1155Config,
        DataTypes.CalculateUserAccountDataParams memory params
    ) internal view returns (uint256, uint256, uint256, uint256, uint256, bool) {
        if (params.userConfig.isEmpty() && !userERC1155Config.isUsingAsCollateralAny()) {
            return (0, 0, 0, 0, type(uint256).max, false);
        }

        CalculateUserAccountDataVars memory vars;

        while (vars.i < params.reservesCount) {
            if (!params.userConfig.isUsingAsCollateralOrBorrowing(vars.i)) {
                unchecked {
                    ++vars.i;
                }
                continue;
            }

            vars.currentReserveAddress = reservesList[vars.i];

            if (vars.currentReserveAddress == address(0)) {
                unchecked {
                    ++vars.i;
                }
                continue;
            }

            DataTypes.ReserveData storage currentReserve = reservesData[vars.currentReserveAddress];

            (vars.ltv, vars.liquidationThreshold,, vars.decimals,) = currentReserve.configuration.getParams();

            unchecked {
                vars.assetUnit = 10 ** vars.decimals;
            }

            vars.assetPrice = IPriceOracleGetter(params.oracle).getAssetPrice(vars.currentReserveAddress);

            if (vars.liquidationThreshold != 0 && params.userConfig.isUsingAsCollateral(vars.i)) {
                vars.userBalanceInBaseCurrency =
                    _getUserBalanceInBaseCurrency(params.user, currentReserve, vars.assetPrice, vars.assetUnit);

                vars.totalCollateralInBaseCurrency += vars.userBalanceInBaseCurrency;

                if (vars.ltv != 0) {
                    vars.avgLtv += vars.userBalanceInBaseCurrency * vars.ltv;
                } else {
                    vars.hasZeroLtvCollateral = true;
                }

                vars.avgLiquidationThreshold += vars.userBalanceInBaseCurrency * vars.liquidationThreshold;
            }

            if (params.userConfig.isBorrowing(vars.i)) {
                vars.totalDebtInBaseCurrency +=
                    _getUserDebtInBaseCurrency(params.user, currentReserve, vars.assetPrice, vars.assetUnit);
            }

            unchecked {
                ++vars.i;
            }
        }

        for (vars.i = 0; vars.i < userERC1155Config.usedERC1155Reserves.length; vars.i++) {
            vars.currentReserveAddress = userERC1155Config.usedERC1155Reserves[vars.i].asset;
            vars.currentReserveTokenId = userERC1155Config.usedERC1155Reserves[vars.i].tokenId;

            DataTypes.ERC1155ReserveData storage currentReserve = erc1155ReservesData[vars.currentReserveAddress];
            vars.currentReserveConfig = currentReserve.getConfiguration(vars.currentReserveTokenId);

            vars.assetPrice = IPriceOracleGetter(params.oracle).getERC1155AssetPrice(
                vars.currentReserveAddress, vars.currentReserveTokenId
            );

            vars.liquidationThreshold = vars.currentReserveConfig.liquidationThreshold;
            vars.ltv = vars.currentReserveConfig.ltv;

            if (vars.liquidationThreshold != 0) {
                vars.userBalanceInBaseCurrency = INToken(currentReserve.nTokenAddress).balanceOf(
                    params.user, vars.currentReserveTokenId
                ) * vars.assetPrice / IERC1155Supply(vars.currentReserveAddress).totalSupply(vars.currentReserveTokenId);

                vars.totalCollateralInBaseCurrency += vars.userBalanceInBaseCurrency;

                if (vars.ltv != 0) {
                    vars.avgLtv += vars.userBalanceInBaseCurrency * vars.ltv;
                } else {
                    vars.hasZeroLtvCollateral = true;
                }

                vars.avgLiquidationThreshold += vars.userBalanceInBaseCurrency * vars.liquidationThreshold;
            }
        }

        unchecked {
            vars.avgLtv = vars.totalCollateralInBaseCurrency != 0 ? vars.avgLtv / vars.totalCollateralInBaseCurrency : 0;
            vars.avgLiquidationThreshold = vars.totalCollateralInBaseCurrency != 0
                ? vars.avgLiquidationThreshold / vars.totalCollateralInBaseCurrency
                : 0;
        }

        vars.healthFactor = (vars.totalDebtInBaseCurrency == 0)
            ? type(uint256).max
            : (vars.totalCollateralInBaseCurrency.percentMul(vars.avgLiquidationThreshold)).wadDiv(
                vars.totalDebtInBaseCurrency
            );
        return (
            vars.totalCollateralInBaseCurrency,
            vars.totalDebtInBaseCurrency,
            vars.avgLtv,
            vars.avgLiquidationThreshold,
            vars.healthFactor,
            vars.hasZeroLtvCollateral
        );
    }

    /**
     * @notice Calculates the maximum amount that can be borrowed depending on the available collateral, the total debt
     * and the average Loan To Value
     * @param totalCollateralInBaseCurrency The total collateral in the base currency used by the price feed
     * @param totalDebtInBaseCurrency The total borrow balance in the base currency used by the price feed
     * @param ltv The average loan to value
     * @return The amount available to borrow in the base currency of the used by the price feed
     */
    function calculateAvailableBorrows(
        uint256 totalCollateralInBaseCurrency,
        uint256 totalDebtInBaseCurrency,
        uint256 ltv
    ) internal pure returns (uint256) {
        uint256 availableBorrowsInBaseCurrency = totalCollateralInBaseCurrency.percentMul(ltv);

        if (availableBorrowsInBaseCurrency < totalDebtInBaseCurrency) {
            return 0;
        }

        availableBorrowsInBaseCurrency = availableBorrowsInBaseCurrency - totalDebtInBaseCurrency;
        return availableBorrowsInBaseCurrency;
    }

    /**
     * @notice Calculates total debt of the user in the based currency used to normalize the values of the assets
     * @dev This fetches the `balanceOf` of the variable debt tokens for the user. For gas reasons, the
     * variable debt balance is calculated by fetching `scaledBalancesOf` normalized debt, which is cheaper than
     * fetching `balanceOf`
     * @param user The address of the user
     * @param reserve The data of the reserve for which the total debt of the user is being calculated
     * @param assetPrice The price of the asset for which the total debt of the user is being calculated
     * @param assetUnit The value representing one full unit of the asset (10^decimals)
     * @return The total debt of the user normalized to the base currency
     */
    function _getUserDebtInBaseCurrency(
        address user,
        DataTypes.ReserveData storage reserve,
        uint256 assetPrice,
        uint256 assetUnit
    ) private view returns (uint256) {
        // fetching variable debt
        uint256 userTotalDebt = IScaledBalanceToken(reserve.variableDebtTokenAddress).scaledBalanceOf(user);
        if (userTotalDebt != 0) {
            userTotalDebt = userTotalDebt.rayMul(reserve.getNormalizedDebt());
        }

        userTotalDebt = assetPrice * userTotalDebt;

        unchecked {
            return userTotalDebt / assetUnit;
        }
    }

    /**
     * @notice Calculates total yToken balance of the user in the based currency used by the price oracle
     * @dev For gas reasons, the yToken balance is calculated by fetching `scaledBalancesOf` normalized debt, which
     * is cheaper than fetching `balanceOf`
     * @param user The address of the user
     * @param reserve The data of the reserve for which the total yToken balance of the user is being calculated
     * @param assetPrice The price of the asset for which the total yToken balance of the user is being calculated
     * @param assetUnit The value representing one full unit of the asset (10^decimals)
     * @return The total yToken balance of the user normalized to the base currency of the price oracle
     */
    function _getUserBalanceInBaseCurrency(
        address user,
        DataTypes.ReserveData storage reserve,
        uint256 assetPrice,
        uint256 assetUnit
    ) private view returns (uint256) {
        uint256 normalizedIncome = reserve.getNormalizedIncome();
        uint256 balance =
            (IScaledBalanceToken(reserve.yTokenAddress).scaledBalanceOf(user).rayMul(normalizedIncome)) * assetPrice;

        unchecked {
            return balance / assetUnit;
        }
    }
}
