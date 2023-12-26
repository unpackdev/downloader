// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ICurveFactory.sol";
import "./IOracle.sol";

struct OriginSwapData {
    address _origin;
    address _target;
    uint256 _originAmount;
    address _recipient;
    address _curveFactory;
}

struct TargetSwapData {
    address _origin;
    address _target;
    uint256 _targetAmount;
    address _recipient;
    address _curveFactory;
}

struct SwapInfo {
    int128 totalAmount;
    int128 totalFee;
    int128 amountToUser;
    int128 amountToTreasury;
    int128 protocolFeePercentage;
    address treasury;
    ICurveFactory curveFactory;
}

struct DepositData {
    uint256 deposits;
    uint256 minQuote;
    uint256 minBase;
    uint256 quoteAmt;
    uint256 maxQuote;
    uint256 maxBase;
    uint256 baseAmt;
    address token0;
    uint256 token0Bal;
    uint256 token1Bal;
}

struct IntakeNumLpRatioInfo {
    uint256 baseWeight;
    uint256 minBase;
    uint256 maxBase;
    uint256 baseAmt;
    uint256 quoteWeight;
    uint256 minQuote;
    uint256 maxQuote;
    uint256 quoteAmt;
    int128 amount;
    address token0;
    uint256 token0Bal;
    uint256 token1Bal;
}
