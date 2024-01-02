// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import "./IPoolAddressesProvider.sol";

interface IUIPoolDataProvider {
    struct InterestRates {
        uint256 variableRateSlope1;
        uint256 variableRateSlope2;
        uint256 baseVariableBorrowRate;
        uint256 optimalUsageRatio;
    }

    struct AggregatedReserveData {
        address underlyingAsset;
        string name;
        string symbol;
        uint256 decimals;
        uint256 baseLTVasCollateral;
        uint256 reserveLiquidationThreshold;
        uint256 reserveLiquidationBonus;
        uint256 reserveFactor;
        bool usageAsCollateralEnabled;
        bool borrowingEnabled;
        bool isActive;
        bool isFrozen;
        bool isPaused;
        uint128 liquidityIndex;
        uint128 variableBorrowIndex;
        uint128 liquidityRate;
        uint128 variableBorrowRate;
        uint40 lastUpdateTimestamp;
        address yTokenAddress;
        address variableDebtTokenAddress;
        address interestRateStrategyAddress;
        uint256 availableLiquidity;
        uint256 totalScaledVariableDebt;
        uint256 priceInMarketReferenceCurrency;
        address priceOracle;
        uint256 variableRateSlope1;
        uint256 variableRateSlope2;
        uint256 baseVariableBorrowRate;
        uint256 optimalUsageRatio;
        uint128 accruedToTreasury;
        bool flashLoanEnabled;
        uint256 borrowCap;
        uint256 supplyCap;
    }

    struct UserReserveData {
        address underlyingAsset;
        uint256 scaledYTokenBalance;
        bool usageAsCollateralEnabledOnUser;
        uint256 scaledVariableDebt;
    }

    struct UserERC1155ReserveData {
        address asset;
        uint256 tokenId;
        uint256 balance;
        uint256 usdValue;
        uint256 ltv;
        uint256 liquidationThreshold;
        address nTokenAddress;
    }

    struct BaseCurrencyInfo {
        uint256 marketReferenceCurrencyUnit;
        int256 marketReferenceCurrencyPriceInUsd;
        int256 networkBaseTokenPriceInUsd;
        uint8 networkBaseTokenPriceDecimals;
    }

    function getReservesList(IPoolAddressesProvider provider) external view returns (address[] memory);

    function getReservesData(IPoolAddressesProvider provider)
        external
        view
        returns (AggregatedReserveData[] memory, BaseCurrencyInfo memory);

    function getUserReservesData(IPoolAddressesProvider provider, address user)
        external
        view
        returns (UserReserveData[] memory, UserERC1155ReserveData[] memory);
}
