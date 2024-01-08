// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;

import "./PriceOracle.sol";
import "./MoartrollerInterface.sol";
pragma solidity ^0.6.12;


interface LiquidationModelInterface {
    function liquidateCalculateSeizeUserTokens(LiquidateCalculateSeizeUserTokensArgumentsSet memory arguments) external view returns (uint, uint);
    function liquidateCalculateSeizeTokens(LiquidateCalculateSeizeUserTokensArgumentsSet memory arguments) external view returns (uint, uint);

    struct LiquidateCalculateSeizeUserTokensArgumentsSet {
        PriceOracle oracle;
        MoartrollerInterface moartroller;
        address mTokenBorrowed;
        address mTokenCollateral;
        uint actualRepayAmount;
        address accountForLiquidation;
        uint liquidationIncentiveMantissa;

    }
}
