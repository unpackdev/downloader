// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./DefinitiveAssets.sol";
import "./IPool.sol";
import "./IPoolAddressesProvider.sol";
import "./IPriceOracleGetter.sol";
import "./DataTypes.sol";
import "./ReserveConfiguration.sol";

library AaveV3Helper {
    using DefinitiveAssets for IERC20;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using ReserveConfiguration for DataTypes.ReserveData;

    // From Aave docs: Referral program is currently inactive, you can pass 0 as referralCode.
    uint16 public constant REFERRAL_CODE = 0;

    function setEMode(address pool, uint8 categoryId) external {
        IPool(pool).setUserEMode(categoryId);
    }

    function getOraclePriceRatio(
        address pool,
        address tokenAddress,
        address toTokenAddress
    ) public view returns (uint256, uint256) {
        (uint256 tokenPrice, uint256 tokenPrecision, address tokenBaseCurrency) = _getOraclePrice(pool, tokenAddress);
        if (toTokenAddress == tokenBaseCurrency) {
            return (tokenPrice, tokenPrecision);
        }

        (uint256 toTokenPrice, uint256 toTokenPrecision, address toTokenBaseCurrency) = _getOraclePrice(
            pool,
            toTokenAddress
        );

        // If the base currencies are different, perform an intermediary conversion
        if (tokenBaseCurrency != toTokenBaseCurrency) {
            (uint256 conversionPrice, uint256 conversionPrecision, ) = _getOraclePrice(pool, tokenBaseCurrency);

            // Convert the tokenPrice to the base currency of the toToken
            tokenPrice = (tokenPrice * conversionPrecision) / conversionPrice;

            // If the precisions are different, adjust the collateral token precision to match the debt token precision
            if (tokenPrecision != toTokenPrecision) {
                tokenPrice = (tokenPrice * toTokenPrecision) / tokenPrecision;
            }
        }

        return ((tokenPrice * toTokenPrecision) / toTokenPrice, toTokenPrecision);
    }

    function borrow(
        address pool,
        address asset,
        uint256 amount,
        DataTypes.InterestRateMode interestRateMode,
        address onBehalfOf
    ) external {
        if (amount > 0) {
            IPool(pool).borrow(asset, amount, uint256(interestRateMode), REFERRAL_CODE, onBehalfOf);
        }
    }

    function repay(
        address pool,
        address asset,
        uint256 amount,
        DataTypes.InterestRateMode interestRateMode,
        address onBehalfOf
    ) external {
        if (amount > 0) {
            IERC20(asset).resetAndSafeIncreaseAllowance(onBehalfOf, pool, amount);
            IPool(pool).repay(asset, amount, uint256(interestRateMode), onBehalfOf);
        }
    }

    function supply(address pool, address asset, uint256 amount, address onBehalfOf) external {
        if (amount > 0) {
            IERC20(asset).resetAndSafeIncreaseAllowance(onBehalfOf, pool, amount);
            IPool(pool).supply(asset, amount, onBehalfOf, REFERRAL_CODE);
        }
    }

    function decollateralize(address pool, address asset, uint256 amount, address onBehalfOf) external {
        if (amount > 0) {
            // slither-disable-next-line unused-return
            IPool(pool).withdraw(asset, amount, onBehalfOf);
        }
    }

    function getTotalStableDebt(address pool, address underlyingAsset) external view returns (uint256 stableDebt) {
        DataTypes.ReserveData memory reserveData = IPool(pool).getReserveData(underlyingAsset);
        stableDebt = DefinitiveAssets.getBalance(reserveData.stableDebtTokenAddress);
    }

    function getTotalVariableDebt(address pool, address underlyingAsset) external view returns (uint256) {
        DataTypes.ReserveData memory reserveData = IPool(pool).getReserveData(underlyingAsset);
        return DefinitiveAssets.getBalance(reserveData.variableDebtTokenAddress);
    }

    function getTotalCollateral(address pool, address asset) external view returns (uint256) {
        DataTypes.ReserveData memory reserveData = IPool(pool).getReserveData(asset);
        return DefinitiveAssets.getBalance(reserveData.aTokenAddress);
    }

    function getLTV(address pool, address user) external view returns (uint256 ltv) {
        (uint256 totalCollateralBase, uint256 totalDebtBase, , , , ) = IPool(pool).getUserAccountData(user);

        if (totalCollateralBase > 0) {
            ltv = ((totalDebtBase * 1e4) / totalCollateralBase);
        }

        return ltv;
    }

    function _getOraclePrice(
        address pool,
        address asset
    ) internal view returns (uint256 price, uint256 precision, address currency) {
        address provider = address(IPool(pool).ADDRESSES_PROVIDER());
        address oracle = IPoolAddressesProvider(provider).getPriceOracle();
        price = IPriceOracleGetter(oracle).getAssetPrice(asset);
        precision = IPriceOracleGetter(oracle).BASE_CURRENCY_UNIT();
        currency = IPriceOracleGetter(oracle).BASE_CURRENCY();
    }
}
