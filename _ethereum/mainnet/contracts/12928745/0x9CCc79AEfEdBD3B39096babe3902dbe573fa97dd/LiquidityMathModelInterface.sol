// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "./MToken.sol";
import "./MProtection.sol";
import "./PriceOracle.sol";

interface LiquidityMathModelInterface {
    struct LiquidityMathArgumentsSet {
        MToken asset;
        address account;
        uint collateralFactorMantissa;
        MProtection cprotection;
        PriceOracle oracle;
    }
    
    function getMaxOptimizableValue(LiquidityMathArgumentsSet memory _arguments) external view returns (uint);
    function getHypotheticalOptimizableValue(LiquidityMathArgumentsSet memory _arguments) external view returns(uint);
    function getTotalProtectionLockedValue(LiquidityMathArgumentsSet memory _arguments) external view returns(uint, uint);
}