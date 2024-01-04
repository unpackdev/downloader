// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

struct AccountLiquidityLocalVars {
    uint256 sumCollateral;
    uint256 sumBorrowPlusEffects;
    uint256 cTokenBalance;
    uint256 borrowBalance;
    uint256 exchangeRateMantissa;
    uint256 oraclePriceMantissa;
    uint256 collateralFactor;
    uint256 exchangeRate;
    uint256 oraclePrice;
    uint256 tokensToDenom;
}

struct Market {
    bool isListed;
    uint256 collateralFactorMantissa;
    mapping(address => bool) accountMembership;
    bool isComped;
}

struct CompData {
    uint256 tokenPriceInEth;
    uint256 tokenPriceInUsd;
    uint256 exchangeRateStored;
    uint256 balanceOfUser;
    uint256 borrowBalanceStoredUser;
    uint256 supplyRatePerBlock;
    uint256 borrowRatePerBlock;
    uint256 collateralFactor;
    bool isComped;
}
