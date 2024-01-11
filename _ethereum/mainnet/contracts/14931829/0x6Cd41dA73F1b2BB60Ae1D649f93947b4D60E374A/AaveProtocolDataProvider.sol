// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;
pragma experimental ABIEncoderV2;

import "./IERC20Metadata.sol";
import "./IERC721Metadata.sol";
import "./IERC721WithStat.sol";
import "./ILendingPoolAddressesProvider.sol";
import "./ILendingPool.sol";
//import "./IStableDebtToken.sol";
import "./IVariableDebtToken.sol";
import "./ReserveConfiguration.sol";
import "./NFTVaultConfiguration.sol";
import "./UserConfiguration.sol";
import "./DataTypes.sol";

contract AaveProtocolDataProvider {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using NFTVaultConfiguration for DataTypes.NFTVaultConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;

  address constant MKR = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
  address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  struct TokenData {
    string symbol;
    address tokenAddress;
  }

  ILendingPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

  constructor(ILendingPoolAddressesProvider addressesProvider) public {
    ADDRESSES_PROVIDER = addressesProvider;
  }

  function getAllReservesTokens() external view returns (TokenData[] memory) {
    ILendingPool pool = ILendingPool(ADDRESSES_PROVIDER.getLendingPool());
    address[] memory reserves = pool.getReservesList();
    TokenData[] memory reservesTokens = new TokenData[](reserves.length);
    for (uint256 i = 0; i < reserves.length; i++) {
      if (reserves[i] == MKR) {
        reservesTokens[i] = TokenData({symbol: 'MKR', tokenAddress: reserves[i]});
        continue;
      }
      if (reserves[i] == ETH) {
        reservesTokens[i] = TokenData({symbol: 'ETH', tokenAddress: reserves[i]});
        continue;
      }
      reservesTokens[i] = TokenData({
        symbol: IERC20Metadata(reserves[i]).symbol(),
        tokenAddress: reserves[i]
      });
    }
    return reservesTokens;
  }

  function getAlNFTVaultsTokens() external view returns (TokenData[] memory) {
    ILendingPool pool = ILendingPool(ADDRESSES_PROVIDER.getLendingPool());
    address[] memory vaults = pool.getNFTVaultsList();
    TokenData[] memory vaultsTokens = new TokenData[](vaults.length);
    for (uint256 i = 0; i < vaults.length; i++) {
      vaultsTokens[i] = TokenData({
        symbol: IERC721Metadata(vaults[i]).symbol(),
        tokenAddress: vaults[i]
      });
    }
    return vaultsTokens;
  }

  function getAllVTokens() external view returns (TokenData[] memory) {
    ILendingPool pool = ILendingPool(ADDRESSES_PROVIDER.getLendingPool());
    address[] memory reserves = pool.getReservesList();
    TokenData[] memory vTokens = new TokenData[](reserves.length);
    for (uint256 i = 0; i < reserves.length; i++) {
      DataTypes.ReserveData memory reserveData = pool.getReserveData(reserves[i]);
      vTokens[i] = TokenData({
        symbol: IERC20Metadata(reserveData.vTokenAddress).symbol(),
        tokenAddress: reserveData.vTokenAddress
      });
    }
    return vTokens;
  }

  function getAllNTokens() external view returns (TokenData[] memory) {
    ILendingPool pool = ILendingPool(ADDRESSES_PROVIDER.getLendingPool());
    address[] memory vaults = pool.getNFTVaultsList();
    TokenData[] memory nTokens = new TokenData[](vaults.length);
    for (uint256 i = 0; i < vaults.length; i++) {
      DataTypes.NFTVaultData memory vaultData = pool.getNFTVaultData(vaults[i]);
      nTokens[i] = TokenData({
        symbol: IERC721Metadata(vaultData.nTokenAddress).symbol(),
        tokenAddress: vaultData.nTokenAddress
      });
    }
    return nTokens;
  }

  function getReserveConfigurationData(address asset)
    external
    view
    returns (
      uint256 decimals,
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus,
      uint256 reserveFactor,
      bool usageAsCollateralEnabled,
      bool borrowingEnabled,
      bool stableBorrowRateEnabled,
      bool isActive,
      bool isFrozen
    )
  {
    DataTypes.ReserveConfigurationMap memory configuration =
      ILendingPool(ADDRESSES_PROVIDER.getLendingPool()).getConfiguration(asset);

    (ltv, liquidationThreshold, liquidationBonus, decimals, reserveFactor) = configuration
      .getParamsMemory();

    (isActive, isFrozen, borrowingEnabled, stableBorrowRateEnabled) = configuration
      .getFlagsMemory();

    usageAsCollateralEnabled = liquidationThreshold > 0;
  }

  function getNFTVaultConfigurationData(address nft)
    external
    view
    returns (
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus,
      bool usageAsCollateralEnabled,
      bool isActive,
      bool isFrozen
    )
  {
    DataTypes.NFTVaultConfigurationMap memory configuration =
      ILendingPool(ADDRESSES_PROVIDER.getLendingPool()).getNFTVaultConfiguration(nft);

    (ltv, liquidationThreshold, liquidationBonus) = configuration
      .getParamsMemory();

    (isActive, isFrozen) = configuration
      .getFlagsMemory();

    usageAsCollateralEnabled = liquidationThreshold > 0;
  }

  function getReserveData(address asset)
    external
    view
    returns (
      uint256 availableLiquidity,
      uint256 totalStableDebt,
      uint256 totalVariableDebt,
      uint256 liquidityRate,
      uint256 variableBorrowRate,
      uint256 stableBorrowRate,
      uint256 averageStableBorrowRate,
      uint256 liquidityIndex,
      uint256 variableBorrowIndex,
      uint40 lastUpdateTimestamp
    )
  {
    DataTypes.ReserveData memory reserve =
      ILendingPool(ADDRESSES_PROVIDER.getLendingPool()).getReserveData(asset);

    return (
      IERC20Metadata(asset).balanceOf(reserve.vTokenAddress),
      0,//IERC20Metadata(reserve.stableDebtTokenAddress).totalSupply(),
      IERC20Metadata(reserve.variableDebtTokenAddress).totalSupply(),
      reserve.currentLiquidityRate,
      reserve.currentVariableBorrowRate,
      0,//reserve.currentStableBorrowRate,
      0,//IStableDebtToken(reserve.stableDebtTokenAddress).getAverageStableRate(),
      reserve.liquidityIndex,
      reserve.variableBorrowIndex,
      reserve.lastUpdateTimestamp
    );
  }

  function getUserReserveData(address asset, address user)
    external
    view
    returns (
      uint256 currentVTokenBalance,
      uint256 currentStableDebt,
      uint256 currentVariableDebt,
      uint256 principalStableDebt,
      uint256 scaledVariableDebt,
      uint256 stableBorrowRate,
      uint256 liquidityRate,
      uint40 stableRateLastUpdated,
      bool usageAsCollateralEnabled
    )
  {
    DataTypes.ReserveData memory reserve =
      ILendingPool(ADDRESSES_PROVIDER.getLendingPool()).getReserveData(asset);

    DataTypes.UserConfigurationMap memory userConfig =
      ILendingPool(ADDRESSES_PROVIDER.getLendingPool()).getUserConfiguration(user);

    currentVTokenBalance = IERC20Metadata(reserve.vTokenAddress).balanceOf(user);
    currentVariableDebt = IERC20Metadata(reserve.variableDebtTokenAddress).balanceOf(user);
    currentStableDebt = 0;//IERC20Metadata(reserve.stableDebtTokenAddress).balanceOf(user);
    principalStableDebt = 0;//IStableDebtToken(reserve.stableDebtTokenAddress).principalBalanceOf(user);
    scaledVariableDebt = IVariableDebtToken(reserve.variableDebtTokenAddress).scaledBalanceOf(user);
    liquidityRate = reserve.currentLiquidityRate;
    stableBorrowRate = 0;//IStableDebtToken(reserve.stableDebtTokenAddress).getUserStableRate(user);
    stableRateLastUpdated = 0;/*IStableDebtToken(reserve.stableDebtTokenAddress).getUserLastUpdated(
      user
    );*/
    usageAsCollateralEnabled = userConfig.isUsingAsCollateral(reserve.id);
  }

  function getUserNFTVaultData(address nft, address user)
    external
    view
    returns (
      uint256 currentNTokenBalance,
      uint256[] memory tokenIds,
      uint256[] memory amounts,
      bool usageAsCollateralEnabled
    )
  {
    DataTypes.NFTVaultData memory vault =
      ILendingPool(ADDRESSES_PROVIDER.getLendingPool()).getNFTVaultData(nft);

    DataTypes.UserConfigurationMap memory userConfig =
      ILendingPool(ADDRESSES_PROVIDER.getLendingPool()).getUserConfiguration(user);
    currentNTokenBalance = IERC721WithStat(vault.nTokenAddress).balanceOf(user);
    tokenIds = IERC721WithStat(vault.nTokenAddress).tokensByAccount(user);
    amounts = IERC721WithStat(vault.nTokenAddress).balanceOfBatch(user, tokenIds);
    
    usageAsCollateralEnabled = userConfig.isUsingNFTVaultAsCollateral(vault.id);
  }

  function getReserveTokensAddresses(address asset)
    external
    view
    returns (
      address vTokenAddress,
      address stableDebtTokenAddress,
      address variableDebtTokenAddress
    )
  {
    DataTypes.ReserveData memory reserve =
      ILendingPool(ADDRESSES_PROVIDER.getLendingPool()).getReserveData(asset);

    return (
      reserve.vTokenAddress,
      reserve.stableDebtTokenAddress,
      reserve.variableDebtTokenAddress
    );
  }

  function getNFTVaultTokensAddresses(address nft)
    external
    view
    returns (
      address nTokenAddress
    )
  {
    DataTypes.NFTVaultData memory vault =
      ILendingPool(ADDRESSES_PROVIDER.getLendingPool()).getNFTVaultData(nft);

    return vault.nTokenAddress;
  }
}
