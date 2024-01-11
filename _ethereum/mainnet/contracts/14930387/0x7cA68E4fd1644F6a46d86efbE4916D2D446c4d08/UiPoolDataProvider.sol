// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;
pragma experimental ABIEncoderV2;

import "./IERC20Metadata.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./ILendingPoolAddressesProvider.sol";
import "./ILendingPoolAddressesProviderRegistry.sol";
import "./IUiPoolDataProvider.sol";
import "./ILendingPool.sol";
import "./IAaveOracle.sol";
import "./IERC721WithStat.sol";
import "./ITimeLockableERC721.sol";
import "./IVToken.sol";
import "./IVariableDebtToken.sol";
//import "./IStableDebtToken.sol";
import "./WadRayMath.sol";
import "./ReserveConfiguration.sol";
import "./NFTVaultConfiguration.sol";
import "./UserConfiguration.sol";
import "./DataTypes.sol";
import "./IChainlinkAggregator.sol";
import "./DefaultReserveInterestRateStrategy.sol";

contract UiPoolDataProvider is IUiPoolDataProvider {
  using WadRayMath for uint256;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using NFTVaultConfiguration for DataTypes.NFTVaultConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;

  IChainlinkAggregator public immutable networkBaseTokenPriceInUsdProxyAggregator;
  IChainlinkAggregator public immutable marketReferenceCurrencyPriceInUsdProxyAggregator;
  uint256 public constant ETH_CURRENCY_UNIT = 1 ether;


  constructor(
    IChainlinkAggregator _networkBaseTokenPriceInUsdProxyAggregator, 
    IChainlinkAggregator _marketReferenceCurrencyPriceInUsdProxyAggregator
  ) public {
    networkBaseTokenPriceInUsdProxyAggregator = _networkBaseTokenPriceInUsdProxyAggregator;
    marketReferenceCurrencyPriceInUsdProxyAggregator = _marketReferenceCurrencyPriceInUsdProxyAggregator;
  }

  function getInterestRateStrategySlopes(DefaultReserveInterestRateStrategy interestRateStrategy)
    internal
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    return (
      interestRateStrategy.variableRateSlope1(),
      interestRateStrategy.variableRateSlope2(),
      interestRateStrategy.stableRateSlope1(),
      interestRateStrategy.stableRateSlope2()
    );
  }

  function _getReservesList(ILendingPoolAddressesProvider provider)
    internal
    view
    returns (address[] memory)
  {
    ILendingPool lendingPool = ILendingPool(provider.getLendingPool());
    return lendingPool.getReservesList();
  }

  function _getNFTVaultsList(ILendingPoolAddressesProvider provider)
    internal
    view
    returns (address[] memory)
  {
    ILendingPool lendingPool = ILendingPool(provider.getLendingPool());
    return lendingPool.getNFTVaultsList();
  }

  function getReservesList(ILendingPoolAddressesProvider provider)
    public
    view
    override
    returns (address[] memory, address[] memory)
  {
    return (_getReservesList(provider), _getNFTVaultsList(provider));
  }

  function _getBaseCurrencyInfo(ILendingPoolAddressesProvider provider)
    internal
    view
    returns (BaseCurrencyInfo memory)
  {
    IAaveOracle oracle = IAaveOracle(provider.getPriceOracle());
    BaseCurrencyInfo memory baseCurrencyInfo;
    baseCurrencyInfo.networkBaseTokenPriceInUsd = networkBaseTokenPriceInUsdProxyAggregator.latestAnswer();
    baseCurrencyInfo.networkBaseTokenPriceDecimals = networkBaseTokenPriceInUsdProxyAggregator.decimals();

    try oracle.BASE_CURRENCY_UNIT() returns (uint256 baseCurrencyUnit) {
      baseCurrencyInfo.marketReferenceCurrencyUnit = baseCurrencyUnit;
      baseCurrencyInfo.marketReferenceCurrencyPriceInUsd = marketReferenceCurrencyPriceInUsdProxyAggregator.latestAnswer();
    } catch (bytes memory /*lowLevelData*/) {  
      baseCurrencyInfo.marketReferenceCurrencyUnit = ETH_CURRENCY_UNIT;
      baseCurrencyInfo.marketReferenceCurrencyPriceInUsd = marketReferenceCurrencyPriceInUsdProxyAggregator.latestAnswer();
    }
    return baseCurrencyInfo;
  }

  function _getReservesData(ILendingPoolAddressesProvider provider)
    internal
    view
    returns (AggregatedReserveData[] memory)
  {
    IAaveOracle oracle = IAaveOracle(provider.getPriceOracle());
    ILendingPool lendingPool = ILendingPool(provider.getLendingPool());
    address[] memory reserves = lendingPool.getReservesList();
    AggregatedReserveData[] memory reservesData = new AggregatedReserveData[](reserves.length);

    for (uint256 i = 0; i < reserves.length; i++) {
      AggregatedReserveData memory reserveData = reservesData[i];
      reserveData.underlyingAsset = reserves[i];

      // reserve current state
      DataTypes.ReserveData memory baseData =
        lendingPool.getReserveData(reserveData.underlyingAsset);
      reserveData.liquidityIndex = baseData.liquidityIndex;
      reserveData.variableBorrowIndex = baseData.variableBorrowIndex;
      reserveData.liquidityRate = baseData.currentLiquidityRate;
      reserveData.variableBorrowRate = baseData.currentVariableBorrowRate;
      reserveData.stableBorrowRate = baseData.currentStableBorrowRate;
      reserveData.lastUpdateTimestamp = baseData.lastUpdateTimestamp;
      reserveData.vTokenAddress = baseData.vTokenAddress;
      reserveData.stableDebtTokenAddress = baseData.stableDebtTokenAddress;
      reserveData.variableDebtTokenAddress = baseData.variableDebtTokenAddress;
      reserveData.interestRateStrategyAddress = baseData.interestRateStrategyAddress;
      reserveData.priceInMarketReferenceCurrency = oracle.getAssetPrice(reserveData.underlyingAsset);

      reserveData.availableLiquidity = IERC20Metadata(reserveData.underlyingAsset).balanceOf(
        reserveData.vTokenAddress
      );
      reserveData.totalPrincipalStableDebt = 0;
      reserveData.averageStableRate = 0;
      reserveData.stableDebtLastUpdateTimestamp = 0;
      /*(
        reserveData.totalPrincipalStableDebt,
        ,
        reserveData.averageStableRate,
        reserveData.stableDebtLastUpdateTimestamp
      ) = IStableDebtToken(reserveData.stableDebtTokenAddress).getSupplyData();*/
      reserveData.totalScaledVariableDebt = IVariableDebtToken(reserveData.variableDebtTokenAddress)
        .scaledTotalSupply();

      // we're getting this info from the vToken, because some of assets can be not compliant with ETC20Detailed
      reserveData.symbol = IERC20Metadata(reserveData.underlyingAsset).symbol();
      reserveData.name = '';

      (
        reserveData.baseLTVasCollateral,
        reserveData.reserveLiquidationThreshold,
        reserveData.reserveLiquidationBonus,
        reserveData.decimals,
        reserveData.reserveFactor
      ) = baseData.configuration.getParamsMemory();
      (
        reserveData.isActive,
        reserveData.isFrozen,
        reserveData.borrowingEnabled,
        reserveData.stableBorrowRateEnabled
      ) = baseData.configuration.getFlagsMemory();
      reserveData.usageAsCollateralEnabled = reserveData.baseLTVasCollateral != 0;
      (
        reserveData.variableRateSlope1,
        reserveData.variableRateSlope2,
        reserveData.stableRateSlope1,
        reserveData.stableRateSlope2
      ) = getInterestRateStrategySlopes(
        DefaultReserveInterestRateStrategy(reserveData.interestRateStrategyAddress)
      );
    }
    return reservesData;
  }

  function _getNFTVaultsData(ILendingPoolAddressesProvider provider)
    internal
    view
    returns (AggregatedNFTVaultData[] memory)
  {
    IAaveOracle oracle = IAaveOracle(provider.getPriceOracle());
    ILendingPool lendingPool = ILendingPool(provider.getLendingPool());
    address[] memory vaults = lendingPool.getNFTVaultsList();
    AggregatedNFTVaultData[] memory vaultsData = new AggregatedNFTVaultData[](vaults.length);

    for (uint256 i = 0; i < vaults.length; i++) {
      AggregatedNFTVaultData memory vaultData = vaultsData[i];
      vaultData.underlyingAsset = vaults[i];

      // reserve current state
      DataTypes.NFTVaultData memory baseData =
        lendingPool.getNFTVaultData(vaultData.underlyingAsset);
      vaultData.nTokenAddress = baseData.nTokenAddress;
      vaultData.lockActionExpiration = baseData.expiration;
      vaultData.priceInMarketReferenceCurrency = oracle.getAssetPrice(vaultData.underlyingAsset);

      vaultData.totalNumberOfCollateral = IERC721(vaultData.underlyingAsset).balanceOf(
        vaultData.nTokenAddress
      );
      // we're getting this info from the vToken, because some of assets can be not compliant with ETC20Detailed
      vaultData.symbol = IERC721Metadata(vaultData.underlyingAsset).symbol();
      vaultData.name = IERC721Metadata(vaultData.underlyingAsset).name();

      (
        vaultData.baseLTVasCollateral,
        vaultData.reserveLiquidationThreshold,
        vaultData.reserveLiquidationBonus
      ) = baseData.configuration.getParamsMemory();
      (
        vaultData.isActive,
        vaultData.isFrozen
      ) = baseData.configuration.getFlagsMemory();
      vaultData.usageAsCollateralEnabled = vaultData.baseLTVasCollateral != 0;
    }

    return vaultsData;
  }

  function getReservesData(ILendingPoolAddressesProvider provider)
    public
    view
    override
    returns (
      AggregatedReserveData[] memory,
      AggregatedNFTVaultData[] memory,
      BaseCurrencyInfo memory
    )
  {
    return (_getReservesData(provider), _getNFTVaultsData(provider), _getBaseCurrencyInfo(provider));
  }

  function _getUserReservesData(ILendingPoolAddressesProvider provider, address user)
    internal
    view
    returns (UserReserveData[] memory)
  {
    ILendingPool lendingPool = ILendingPool(provider.getLendingPool());
    address[] memory reserves = lendingPool.getReservesList();
    DataTypes.UserConfigurationMap memory userConfig = lendingPool.getUserConfiguration(user);

    UserReserveData[] memory userReservesData =
      new UserReserveData[](user != address(0) ? reserves.length : 0);

    for (uint256 i = 0; i < reserves.length; i++) {
      DataTypes.ReserveData memory baseData = lendingPool.getReserveData(reserves[i]);

      // user reserve data
      userReservesData[i].underlyingAsset = reserves[i];
      userReservesData[i].scaledVTokenBalance = IVToken(baseData.vTokenAddress).scaledBalanceOf(
        user
      );
      userReservesData[i].usageAsCollateralEnabledOnUser = userConfig.isUsingAsCollateral(i);

      if (userConfig.isBorrowing(i)) {
        userReservesData[i].scaledVariableDebt = IVariableDebtToken(
          baseData
            .variableDebtTokenAddress
        )
          .scaledBalanceOf(user);
        userReservesData[i].principalStableDebt = 0;
        /*userReservesData[i].principalStableDebt = IStableDebtToken(baseData.stableDebtTokenAddress)
          .principalBalanceOf(user);
        if (userReservesData[i].principalStableDebt != 0) {
          userReservesData[i].stableBorrowRate = IStableDebtToken(baseData.stableDebtTokenAddress)
            .getUserStableRate(user);
          userReservesData[i].stableBorrowLastUpdateTimestamp = IStableDebtToken(
            baseData
              .stableDebtTokenAddress
          )
            .getUserLastUpdated(user);
        }*/
      }
    }

    return (userReservesData);
  }

  function _getUserNFTVaultsData(ILendingPoolAddressesProvider provider, address user)
    internal
    view
    returns (UserNFTVaultData[] memory)
  {
    ILendingPool lendingPool = ILendingPool(provider.getLendingPool());
    address[] memory vaults = lendingPool.getNFTVaultsList();
    DataTypes.UserConfigurationMap memory userConfig = lendingPool.getUserConfiguration(user);

    UserNFTVaultData[] memory userVaultsData =
      new UserNFTVaultData[](user != address(0) ? vaults.length : 0);

    for (uint256 i = 0; i < vaults.length; i++) {
      DataTypes.NFTVaultData memory baseData = lendingPool.getNFTVaultData(vaults[i]);
      address nTokenAddress = baseData.nTokenAddress;

      // user reserve data
      userVaultsData[i].underlyingAsset = vaults[i];
      userVaultsData[i].nTokenBalance = IERC721(nTokenAddress).balanceOf(user);
      (userVaultsData[i].tokenIds, userVaultsData[i].locks)
          = ITimeLockableERC721(nTokenAddress).tokensAndLocksByAccount(user);
      userVaultsData[i].amounts = IERC721WithStat(nTokenAddress).balanceOfBatch(user, userVaultsData[i].tokenIds);
      userVaultsData[i].usageAsCollateralEnabledOnUser = userConfig.isUsingNFTVaultAsCollateral(i);
    }
    return (userVaultsData);
  }

  function getUserReservesData(ILendingPoolAddressesProvider provider, address user)
    public
    view
    override
    returns (
      UserReserveData[] memory,
      UserNFTVaultData[] memory
    )
  {
    return (_getUserReservesData(provider, user), _getUserNFTVaultsData(provider, user));
  }

  function getPoolsList(ILendingPoolAddressesProviderRegistry registry)
    public
    view
    override
    returns (address[] memory)
  {
    return registry.getAddressesProvidersList();
  }

  function getReservesDataFromAllPools(ILendingPoolAddressesProviderRegistry registry)
    public
    view
    override
    returns (PoolData[] memory)
  {
    address[] memory addressesProvidersList = registry.getAddressesProvidersList();
    PoolData[] memory poolsData = new PoolData[](addressesProvidersList.length);
    for(uint256 i = 0; i < addressesProvidersList.length; ++i) {
      ILendingPoolAddressesProvider provider = ILendingPoolAddressesProvider(addressesProvidersList[i]);
      poolsData[i].marketId = provider.getMarketId();
      poolsData[i].currencyInfo = _getBaseCurrencyInfo(provider);
      poolsData[i].reservesData = _getReservesData(provider);
      poolsData[i].nftVaultsData = _getNFTVaultsData(provider);
    }
    return poolsData;
  }
  
  function getUserReservesDataFromAllPools(ILendingPoolAddressesProviderRegistry registry, address user)
    public
    view
    override
    returns (UserPoolData[] memory)
  {
    address[] memory addressesProvidersList = registry.getAddressesProvidersList();
    UserPoolData[] memory userPoolsData = new UserPoolData[](addressesProvidersList.length);
    for(uint256 i = 0; i < addressesProvidersList.length; ++i) {
      ILendingPoolAddressesProvider provider = ILendingPoolAddressesProvider(addressesProvidersList[i]);
      userPoolsData[i].marketId = provider.getMarketId();
      userPoolsData[i].userReservesData = _getUserReservesData(provider, user);
      userPoolsData[i].userNFTVaultsData = _getUserNFTVaultsData(provider, user);
    }
    return userPoolsData;

  }
}