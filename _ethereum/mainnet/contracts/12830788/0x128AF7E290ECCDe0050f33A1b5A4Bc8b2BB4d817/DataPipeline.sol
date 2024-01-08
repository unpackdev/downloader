// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./IERC20.sol";

import "./DataStruct.sol";

import "./ILToken.sol";
import "./IDToken.sol";
import "./IMoneyPool.sol";
import "./ITokenizer.sol";

/**
 * @title ELYFI Data Pipeline
 * @author ELYSIA
 * @dev The data pipeline contract is to help integrating the data of user and reserve in ELYFI.
 * Each reserve has a seperate data pipeline.
 */
contract DataPipeline {
  IMoneyPool public moneyPool;

  constructor(address moneyPool_) {
    moneyPool = IMoneyPool(moneyPool_);
  }

  struct UserDataLocalVars {
    uint256 underlyingAssetBalance;
    uint256 lTokenBalance;
    uint256 implicitLtokenBalance;
    uint256 dTokenBalance;
    uint256 principalDTokenBalance;
    uint256 averageRealAssetBorrowRate;
    uint256 lastUpdateTimestamp;
  }

  /**
   * @dev Returns the user's data for asset.
   */
  function getUserData(address asset, address user)
    external
    view
    returns (UserDataLocalVars memory)
  {
    UserDataLocalVars memory vars;
    DataStruct.ReserveData memory reserve = moneyPool.getReserveData(asset);

    vars.underlyingAssetBalance = IERC20(asset).balanceOf(user);
    vars.lTokenBalance = ILToken(reserve.lTokenAddress).balanceOf(user);
    vars.implicitLtokenBalance = ILToken(reserve.lTokenAddress).implicitBalanceOf(user);
    vars.dTokenBalance = IDToken(reserve.dTokenAddress).balanceOf(user);
    vars.principalDTokenBalance = IDToken(reserve.dTokenAddress).principalBalanceOf(user);
    vars.averageRealAssetBorrowRate = IDToken(reserve.dTokenAddress)
    .getUserAverageRealAssetBorrowRate(user);
    vars.lastUpdateTimestamp = IDToken(reserve.dTokenAddress).getUserLastUpdateTimestamp(user);

    return vars;
  }

  struct ReserveDataLocalVars {
    uint256 totalLTokenSupply;
    uint256 implicitLTokenSupply;
    uint256 lTokenInterestIndex;
    uint256 principalDTokenSupply;
    uint256 totalDTokenSupply;
    uint256 averageRealAssetBorrowRate;
    uint256 dTokenLastUpdateTimestamp;
    uint256 borrowAPY;
    uint256 depositAPY;
    uint256 moneyPooLastUpdateTimestamp;
  }

  /**
   * @dev Returns the reserve's data for asset.
   */
  function getReserveData(address asset) external view returns (ReserveDataLocalVars memory) {
    ReserveDataLocalVars memory vars;
    DataStruct.ReserveData memory reserve = moneyPool.getReserveData(asset);

    vars.totalLTokenSupply = ILToken(reserve.lTokenAddress).totalSupply();
    vars.implicitLTokenSupply = ILToken(reserve.lTokenAddress).implicitTotalSupply();
    vars.lTokenInterestIndex = reserve.lTokenInterestIndex;
    (
      vars.principalDTokenSupply,
      vars.totalDTokenSupply,
      vars.averageRealAssetBorrowRate,
      vars.dTokenLastUpdateTimestamp
    ) = IDToken(reserve.dTokenAddress).getDTokenData();
    vars.borrowAPY = reserve.borrowAPY;
    vars.depositAPY = reserve.depositAPY;
    vars.moneyPooLastUpdateTimestamp = reserve.lastUpdateTimestamp;

    return vars;
  }

  struct AssetBondStateDataLocalVars {
    DataStruct.AssetBondState assetBondState;
    address tokenOwner;
    uint256 debtOnMoneyPool;
    uint256 feeOnCollateralServiceProvider;
  }

  function getAssetBondStateData(address asset, uint256 tokenId)
    external
    view
    returns (AssetBondStateDataLocalVars memory)
  {
    AssetBondStateDataLocalVars memory vars;

    DataStruct.ReserveData memory reserve = moneyPool.getReserveData(asset);
    DataStruct.AssetBondData memory assetBond = ITokenizer(reserve.tokenizerAddress)
    .getAssetBondData(tokenId);

    vars.assetBondState = assetBond.state;
    vars.tokenOwner = ITokenizer(reserve.tokenizerAddress).ownerOf(tokenId);
    (vars.debtOnMoneyPool, vars.feeOnCollateralServiceProvider) = ITokenizer(
      reserve.tokenizerAddress
    ).getAssetBondDebtData(tokenId);

    return vars;
  }
}
