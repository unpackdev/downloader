// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract InterestRateModel {
    uint256 public baseRatePerYear;
    uint256 public multiplierPerYear;

    constructor(uint256 baseRatePerYear_, uint256 multiplierPerYear_) {
        baseRatePerYear = baseRatePerYear_;
        multiplierPerYear = multiplierPerYear_;
    }

    function getBorrowRate(uint256 cash, uint256 borrows, uint256 reserves) public view returns (uint256) {
        uint256 utilizationRate = (borrows * 1e18) / (cash + borrows - reserves);
        uint256 borrowRate = (utilizationRate * multiplierPerYear) / 1e18 + baseRatePerYear;
        return borrowRate;
    }

    function getSupplyRate(uint256 cash, uint256 borrows, uint256 reserves, uint256 reserveFactorMantissa) public view returns (uint256) {
        uint256 oneMinusReserveFactor = 1e18 - reserveFactorMantissa;
        uint256 borrowRate = getBorrowRate(cash, borrows, reserves);
        uint256 rateToPool = (borrowRate * oneMinusReserveFactor) / 1e18;
        uint256 utilizationRate = (borrows * 1e18) / (cash + borrows - reserves);
        uint256 supplyRate = (utilizationRate * rateToPool) / 1e18;
        return supplyRate;
    }
}