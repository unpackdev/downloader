// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.21;

interface IBaseLeverage {
  enum FlashLoanType {
    AAVE,
    BALANCER
  }

  enum SwapType {
    NONE,
    NO_SWAP,
    UNISWAP,
    BALANCER,
    CURVE
  }

  struct MultipSwapPath {
    address[9] routes;
    uint256[3][4] routeParams;
    // uniswap/balancer/curve
    SwapType swapType;
    uint256 poolCount;
    address swapFrom;
    address swapTo;
    uint256 inAmount;
    uint256 outAmount;
  }

  struct SwapInfo {
    MultipSwapPath[3] paths;
    MultipSwapPath[3] reversePaths;
    uint256 pathLength;
  }

  struct FlashLoanParams {
    bool isEnterPosition;
    uint256 minCollateralAmount;
    address user;
    address collateralAsset;
    address silo;
    SwapInfo swapInfo;
  }

  struct LeverageParams {
    address user;
    uint256 principal;
    uint256 leverage;
    address borrowAsset;
    address collateralAsset;
    address silo;
    FlashLoanType flashLoanType;
    SwapInfo swapInfo;
  }

  function enterPositionWithFlashloan(
    uint256 _principal,
    uint256 _leverage,
    address _borrowAsset,
    address _collateralAsset,
    address _silo,
    FlashLoanType _flashLoanType,
    SwapInfo calldata _swapInfo
  ) external;

  function withdrawWithFlashloan(
    uint256 _repayAmount,
    uint256 _requiredAmount,
    address _borrowAsset,
    address _collateralAsset,
    address _silo,
    FlashLoanType _flashLoanType,
    SwapInfo calldata _swapInfo
  ) external;
}
