// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;
pragma experimental ABIEncoderV2;

import "./ILendingPoolAddressesProvider.sol";
import "./ILendingPoolAddressesProviderRegistry.sol";
import "./DataTypes.sol";

interface IUiPoolDataProvider {
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
    bool stableBorrowRateEnabled;
    bool isActive;
    bool isFrozen;
    // base data
    uint128 liquidityIndex;
    uint128 variableBorrowIndex;
    uint128 liquidityRate;
    uint128 variableBorrowRate;
    uint128 stableBorrowRate;
    uint40 lastUpdateTimestamp;
    address vTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    address interestRateStrategyAddress;
    //
    uint256 availableLiquidity;
    uint256 totalPrincipalStableDebt;
    uint256 averageStableRate;
    uint256 stableDebtLastUpdateTimestamp;
    uint256 totalScaledVariableDebt;
    uint256 priceInMarketReferenceCurrency;
    uint256 variableRateSlope1;
    uint256 variableRateSlope2;
    uint256 stableRateSlope1;
    uint256 stableRateSlope2;
  }

  struct AggregatedNFTVaultData {
    address underlyingAsset;
    string name;
    string symbol;
    uint256 baseLTVasCollateral;
    uint256 reserveLiquidationThreshold;
    uint256 reserveLiquidationBonus;
    bool usageAsCollateralEnabled;
    bool isActive;
    bool isFrozen;
    uint40 lockActionExpiration;
    // base data
    address nTokenAddress;
    uint256 totalNumberOfCollateral;
    uint256 priceInMarketReferenceCurrency;
  }

  struct UserReserveData {
    address underlyingAsset;
    uint256 scaledVTokenBalance;
    bool usageAsCollateralEnabledOnUser;
    uint256 stableBorrowRate;
    uint256 scaledVariableDebt;
    uint256 principalStableDebt;
    uint256 stableBorrowLastUpdateTimestamp;
  }

  struct UserNFTVaultData {
    address underlyingAsset;
    uint256 nTokenBalance;
    uint256[] tokenIds;
    uint256[] amounts;
    DataTypes.TimeLock[] locks;
    bool usageAsCollateralEnabledOnUser;
  }

  struct BaseCurrencyInfo {
    uint256 marketReferenceCurrencyUnit;
    int256 marketReferenceCurrencyPriceInUsd;
    int256 networkBaseTokenPriceInUsd;
    uint8 networkBaseTokenPriceDecimals;
  }

  struct PoolData {
    string marketId;
    BaseCurrencyInfo currencyInfo;
    AggregatedReserveData[] reservesData;
    AggregatedNFTVaultData[] nftVaultsData;
  }

  struct UserPoolData {
    string marketId;
    UserReserveData[] userReservesData;
    UserNFTVaultData[] userNFTVaultsData;
  }

  function getReservesList(ILendingPoolAddressesProvider provider)
    external
    view
    returns (address[] memory, address[] memory);

  function getReservesData(ILendingPoolAddressesProvider provider)
    external
    view
    returns (
      AggregatedReserveData[] memory,
      AggregatedNFTVaultData[] memory,
      BaseCurrencyInfo memory
    );

  function getUserReservesData(ILendingPoolAddressesProvider provider, address user)
    external
    view
    returns (
      UserReserveData[] memory,
      UserNFTVaultData[] memory
    );

  function getPoolsList(ILendingPoolAddressesProviderRegistry registry)
    external
    view
    returns (address[] memory);

  function getReservesDataFromAllPools(ILendingPoolAddressesProviderRegistry registry)
    external
    view
    returns (PoolData[] memory);
  
  function getUserReservesDataFromAllPools(ILendingPoolAddressesProviderRegistry registry, address user)
    external
    view
    returns (UserPoolData[] memory);
}