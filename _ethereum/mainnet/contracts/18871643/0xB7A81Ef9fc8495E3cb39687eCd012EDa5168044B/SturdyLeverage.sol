// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.21;

import "./BaseLeverage.sol";
import "./ISturdyPair.sol";

contract SturdyLeverage is BaseLeverage {
  using SafeERC20 for IERC20;

  error LV_REPAY_FAILED();

  function _withdrawWithFlashloan(
    address _borrowAsset,
    uint256 _borrowedAmount,
    IBaseLeverage.FlashLoanParams memory _params
  ) internal override {
    // repay
    _repay(_borrowAsset, _params.silo, _borrowedAmount, _params.user);

    // withdraw collateral
    ISturdyPair pair = ISturdyPair(_params.silo);
    if (_params.collateralAsset != pair.collateralContract()) revert LV_INVALID_CONFIGURATION();

    ( uint256 LTV_PRECISION,,,, uint256 EXCHANGE_PRECISION,,,) = ISturdyPair(_params.silo).getConstants();
    ISturdyPair(_params.silo).addInterest(false);

    (,, uint256 exchangeRate) = ISturdyPair(_params.silo).updateExchangeRate();
    uint256 borrowShares = pair.userBorrowShares(_params.user);
    uint256 borrowAmount =  ISturdyPair(_params.silo).toBorrowAmount(borrowShares, true, false);
    uint256 collateralAmount = pair.userCollateralBalance(_params.user);
    uint256 withdrawalAmount = collateralAmount - (borrowAmount * exchangeRate * LTV_PRECISION / EXCHANGE_PRECISION / pair.maxLTV());
    if (withdrawalAmount < _params.minCollateralAmount) revert LV_SUPPLY_NOT_ALLOWED();

    _remove(withdrawalAmount, _params.silo, 0, _params.user);

    // collateral -> borrow asset
    _swapFrom(_borrowAsset, _params.collateralAsset, _params.swapInfo.reversePaths, _params.swapInfo.pathLength);
  }

  function _supply(
    address _collateralAsset, 
    address _silo, 
    uint256 _amount, 
    address _user
  ) internal override {
    IERC20(_collateralAsset).safeApprove(_silo, 0);
    IERC20(_collateralAsset).safeApprove(_silo, _amount);
    ISturdyPair(_silo).addCollateral(_amount, _user);
  }

  function _remove(
    uint256 _amount, 
    address _silo, 
    uint256 _slippage, 
    address _user
  ) internal override {
    ISturdyPair(_silo).removeCollateralFrom(_amount, address(this), _user);
  }

  function _borrow(
    address _borrowAsset, 
    address _silo, 
    uint256 _amount, 
    address _borrower 
  ) internal override {
    ISturdyPair(_silo).borrowAssetOnBehalfOf(_amount, _borrower);
  }

  function _repay(
    address _borrowAsset, 
    address _silo, 
    uint256 _amount, 
    address _borrower
  ) internal override {
    ISturdyPair(_silo).addInterest(false);

    uint256 borrowShares =  ISturdyPair(_silo).toBorrowShares(_amount, false, false);

    IERC20(_borrowAsset).safeApprove(_silo, 0);
    IERC20(_borrowAsset).safeApprove(_silo, _amount);

    uint256 paybackAmount = ISturdyPair(_silo).repayAsset(borrowShares, _borrower);
    if (paybackAmount == 0) revert LV_REPAY_FAILED();
  }

  function _processSwap(
    uint256 _amount,
    IBaseLeverage.MultipSwapPath memory _path,
    bool _isFrom,
    bool _checkOutAmount
  ) internal override returns (uint256) {
    return _swapByPath(_amount, _path, _checkOutAmount);
  }
}