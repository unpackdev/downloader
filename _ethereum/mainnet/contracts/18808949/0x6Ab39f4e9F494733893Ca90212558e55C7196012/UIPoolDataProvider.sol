// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import "./IERC20Metadata.sol";
import "./IERC1155.sol";
import "./IPoolAddressesProvider.sol";
import "./IPool.sol";
import "./IYLDROracle.sol";
import "./IYToken.sol";
import "./IVariableDebtToken.sol";
import {DefaultReserveInterestRateStrategy} from
    "@yldr-lending/core/src/protocol/pool/DefaultReserveInterestRateStrategy.sol";
import "./YLDRProtocolDataProvider.sol";
import "./WadRayMath.sol";
import "./ReserveConfiguration.sol";
import "./UserConfiguration.sol";
import "./DataTypes.sol";
import "./IUIPoolDataProvider.sol";
import "./IChainlinkAggregatorV3.sol";
import "./IERC1155ConfigurationProvider.sol";
import "./IERC1155Supply.sol";

contract UIPoolDataProvider is IUIPoolDataProvider {
    using WadRayMath for uint256;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;

    IChainlinkAggregatorV3 public immutable networkBaseTokenPriceInUsdProxyAggregator;

    constructor(IChainlinkAggregatorV3 _networkBaseTokenPriceInUsdProxyAggregator) {
        networkBaseTokenPriceInUsdProxyAggregator = _networkBaseTokenPriceInUsdProxyAggregator;
    }

    function getReservesList(IPoolAddressesProvider provider) public view override returns (address[] memory) {
        IPool pool = IPool(provider.getPool());
        return pool.getReservesList();
    }

    function getReservesData(IPoolAddressesProvider provider)
        public
        view
        override
        returns (AggregatedReserveData[] memory reservesData, BaseCurrencyInfo memory baseCurrencyInfo)
    {
        IYLDROracle oracle = IYLDROracle(provider.getPriceOracle());
        IPool pool = IPool(provider.getPool());
        YLDRProtocolDataProvider poolDataProvider = YLDRProtocolDataProvider(provider.getPoolDataProvider());

        address[] memory reserves = pool.getReservesList();
        reservesData = new AggregatedReserveData[](reserves.length);

        for (uint256 i = 0; i < reserves.length; i++) {
            AggregatedReserveData memory reserveData = reservesData[i];
            reserveData.underlyingAsset = reserves[i];

            // reserve current state
            DataTypes.ReserveData memory baseData = pool.getReserveData(reserveData.underlyingAsset);
            //the liquidity index. Expressed in ray
            reserveData.liquidityIndex = baseData.liquidityIndex;
            //variable borrow index. Expressed in ray
            reserveData.variableBorrowIndex = baseData.variableBorrowIndex;
            //the current supply rate. Expressed in ray
            reserveData.liquidityRate = baseData.currentLiquidityRate;
            //the current variable borrow rate. Expressed in ray
            reserveData.variableBorrowRate = baseData.currentVariableBorrowRate;
            //the current stable borrow rate. Expressed in ray
            reserveData.lastUpdateTimestamp = baseData.lastUpdateTimestamp;
            reserveData.yTokenAddress = baseData.yTokenAddress;
            reserveData.variableDebtTokenAddress = baseData.variableDebtTokenAddress;
            //address of the interest rate strategy
            reserveData.interestRateStrategyAddress = baseData.interestRateStrategyAddress;
            reserveData.priceInMarketReferenceCurrency = oracle.getAssetPrice(reserveData.underlyingAsset);
            reserveData.priceOracle = oracle.getSourceOfAsset(reserveData.underlyingAsset);
            reserveData.availableLiquidity =
                IERC20Metadata(reserveData.underlyingAsset).balanceOf(reserveData.yTokenAddress);
            reserveData.totalScaledVariableDebt =
                IVariableDebtToken(reserveData.variableDebtTokenAddress).scaledTotalSupply();

            reserveData.symbol = IERC20Metadata(reserveData.underlyingAsset).symbol();
            reserveData.name = IERC20Metadata(reserveData.underlyingAsset).name();

            //stores the reserve configuration
            DataTypes.ReserveConfigurationMap memory reserveConfigurationMap = baseData.configuration;
            (
                reserveData.baseLTVasCollateral,
                reserveData.reserveLiquidationThreshold,
                reserveData.reserveLiquidationBonus,
                reserveData.decimals,
                reserveData.reserveFactor
            ) = reserveConfigurationMap.getParams();
            reserveData.usageAsCollateralEnabled = reserveData.baseLTVasCollateral != 0;

            (reserveData.isActive, reserveData.isFrozen, reserveData.borrowingEnabled, reserveData.isPaused) =
                reserveConfigurationMap.getFlags();

            // interest rates
            try DefaultReserveInterestRateStrategy(reserveData.interestRateStrategyAddress).getVariableRateSlope1()
            returns (uint256 res) {
                reserveData.variableRateSlope1 = res;
            } catch {}
            try DefaultReserveInterestRateStrategy(reserveData.interestRateStrategyAddress).getVariableRateSlope2()
            returns (uint256 res) {
                reserveData.variableRateSlope2 = res;
            } catch {}
            try DefaultReserveInterestRateStrategy(reserveData.interestRateStrategyAddress).getBaseVariableBorrowRate()
            returns (uint256 res) {
                reserveData.baseVariableBorrowRate = res;
            } catch {}
            try DefaultReserveInterestRateStrategy(reserveData.interestRateStrategyAddress).OPTIMAL_USAGE_RATIO()
            returns (uint256 res) {
                reserveData.optimalUsageRatio = res;
            } catch {}

            (reserveData.borrowCap, reserveData.supplyCap) = reserveConfigurationMap.getCaps();

            try poolDataProvider.getFlashLoanEnabled(reserveData.underlyingAsset) returns (bool flashLoanEnabled) {
                reserveData.flashLoanEnabled = flashLoanEnabled;
            } catch (bytes memory) {
                reserveData.flashLoanEnabled = true;
            }

            reserveData.accruedToTreasury = baseData.accruedToTreasury;
        }

        (, baseCurrencyInfo.networkBaseTokenPriceInUsd,,,) = networkBaseTokenPriceInUsdProxyAggregator.latestRoundData();
        baseCurrencyInfo.networkBaseTokenPriceDecimals = networkBaseTokenPriceInUsdProxyAggregator.decimals();

        baseCurrencyInfo.marketReferenceCurrencyUnit = oracle.BASE_CURRENCY_UNIT();
        baseCurrencyInfo.marketReferenceCurrencyPriceInUsd = int256(baseCurrencyInfo.marketReferenceCurrencyUnit);
    }

    function getUserReservesData(IPoolAddressesProvider provider, address user)
        external
        view
        override
        returns (UserReserveData[] memory userReservesData, UserERC1155ReserveData[] memory userERC1155ReservesData)
    {
        IPool pool = IPool(provider.getPool());
        IYLDROracle oracle = IYLDROracle(provider.getPriceOracle());
        address[] memory reserves = pool.getReservesList();
        DataTypes.UserConfigurationMap memory userConfig = pool.getUserConfiguration(user);

        userReservesData = new UserReserveData[](user != address(0) ? reserves.length : 0);

        for (uint256 i = 0; i < reserves.length; i++) {
            DataTypes.ReserveData memory baseData = pool.getReserveData(reserves[i]);

            // user reserve data
            userReservesData[i].underlyingAsset = reserves[i];
            userReservesData[i].scaledYTokenBalance = IYToken(baseData.yTokenAddress).scaledBalanceOf(user);
            userReservesData[i].usageAsCollateralEnabledOnUser = userConfig.isUsingAsCollateral(i);

            if (userConfig.isBorrowing(i)) {
                userReservesData[i].scaledVariableDebt =
                    IVariableDebtToken(baseData.variableDebtTokenAddress).scaledBalanceOf(user);
            }
        }

        DataTypes.ERC1155ReserveUsageData[] memory userUsedERC1155Reserves = pool.getUserUsedERC1155Reserves(user);
        userERC1155ReservesData = new UserERC1155ReserveData[](userUsedERC1155Reserves.length);

        for (uint256 i = 0; i < userUsedERC1155Reserves.length; i++) {
            uint256 tokenId = userUsedERC1155Reserves[i].tokenId;
            address asset = userUsedERC1155Reserves[i].asset;
            DataTypes.ERC1155ReserveData memory reserveData = pool.getERC1155ReserveData(asset);
            DataTypes.ERC1155ReserveConfiguration memory config =
                IERC1155ConfigurationProvider(reserveData.configurationProvider).getERC1155ReserveConfig(tokenId);
            uint256 balance = IERC1155(reserveData.nTokenAddress).balanceOf(user, tokenId);
            userERC1155ReservesData[i] = UserERC1155ReserveData({
                asset: asset,
                tokenId: tokenId,
                balance: balance,
                ltv: config.ltv,
                liquidationThreshold: config.liquidationThreshold,
                usdValue: balance * oracle.getERC1155AssetPrice(asset, tokenId) / IERC1155Supply(asset).totalSupply(tokenId),
                nTokenAddress: reserveData.nTokenAddress
            });
        }
    }
}
