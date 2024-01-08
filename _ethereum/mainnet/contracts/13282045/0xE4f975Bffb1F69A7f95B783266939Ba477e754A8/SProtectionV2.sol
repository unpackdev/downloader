// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

struct CollateralAndLT {
    address reserve;
    uint256 collateralInETH;
    uint256 liquidationThreshold;
}

struct DebtTknData {
    address reserve;
    uint256 debtBalanceInETH;
    uint256 rateMode;
}

struct CalculateUserAccountDataVars {
    uint256 liquidationThreshold;
    uint256 decimals;
    uint256 priceInETH;
    uint256 collateralBalanceInETH;
    uint256 stableDebtTokenBalanceInETH;
    uint256 variableDebtTokenBalanceInETH;
}

struct BestColAndDebtDataInput {
    bytes32 id;
    address user;
}

struct BestColAndDebtDataResult {
    bytes32 id;
    DebtTknData debtToken;
    CollateralAndLT[] colAndLTs;
    uint256 totalCollateralETH;
    uint256 totalDebtETH;
    uint256 currentLiquidationThreshold;
    uint256 flashloanPremiumBps;
    string message;
}
