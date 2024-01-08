// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

interface ITokenPairPriceFeed {
    /// Fetches the rate between a given token pair
    /// @param rateConversionData Data that specifies the target tokens (each ITokenPairPriceFeed might have different input requirements)
    /// @return rate The rate between the provided tokens
    /// @return rateDenominator The denominator (scale) for the result
    function getRate(bytes32 rateConversionData) external view returns (uint256 rate, uint256 rateDenominator);
}
