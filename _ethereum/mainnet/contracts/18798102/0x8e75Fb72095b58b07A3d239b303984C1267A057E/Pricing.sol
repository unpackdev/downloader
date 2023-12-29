// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.20;

import "./Types.sol";
import "./Math.sol";

library AlbaCollectionPricing {
    /**
     * @notice Returns the current price of the sale.
     * @dev Wrapper for different pricing strategies based on sale type.
     */
    function getPrice(SaleConfig storage saleConfig) public view returns (uint256) {
        if (saleConfig.saleType == SaleType.FixedPrice || saleConfig.saleType == SaleType.FixedPriceTimeLimited) {
            return saleConfig.initialPrice;
        }
        if (block.timestamp <= saleConfig.startTime) {
            return saleConfig.initialPrice;
        }
        if (saleConfig.saleType == SaleType.ExponentialDutchAuction) {
            return _getPriceExponentialDA(saleConfig);
        }
        return 0;
    }

    /**
     * @notice Returns the current price of the sale using a continuous dutch auction pricing strategy.
     * @dev This works by computing the time elapsed since the start of the auction, and then interpolating
     * the price based on the initial price and the final price. The interpolation is linear.
     */
    function _getPriceExponentialDA(SaleConfig storage saleConfig) internal view returns (uint256) {
        if (block.timestamp >= saleConfig.auctionEndTime) {
            return saleConfig.finalPrice;
        }

        uint256 timeElapsed = block.timestamp - saleConfig.startTime;
        uint40 totalDuration = saleConfig.auctionEndTime - saleConfig.startTime;

        // This choice guarantees that `elapsed/tau < 5` meaning that the approximant is applicable (with rel error < 1%)
        // and that the price difference has sufficiently decayed (to <0.007) at the end of the auction.
        uint40 tau = totalDuration / 5;

        (uint256 expNumerator, uint256 expDenominator) =
            Math.expPadeApprox5(int48(int256(timeElapsed)), -int48(uint48(tau)));

        uint256 priceDifference = saleConfig.initialPrice - saleConfig.finalPrice;
        return saleConfig.finalPrice + (priceDifference * expNumerator) / expDenominator;
    }
}
