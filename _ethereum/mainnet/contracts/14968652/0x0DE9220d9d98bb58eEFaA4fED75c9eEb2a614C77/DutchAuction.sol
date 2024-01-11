// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./CollectionBase.sol";

/**
 * Faux dutch auction library - purchase price descends to 0 over the duration of the sale at a set rate.
 */
abstract contract DutchAuction is CollectionBase {

    struct DutchAuctionData {
        uint256 minimumPrice;
        uint256 priceDropInterval;
        uint256 priceDropMagnitude;
    }

    // If set, price during sale will not drop below this threshold.
    uint256 public minimumPrice;

    uint256 public priceDropInterval;
    uint256 public priceDropMagnitude;

    /**
     * @dev returns pricing data used to compute current price
     */
    function pricingData() external view returns (DutchAuctionData memory) {
        return DutchAuctionData(minimumPrice, priceDropInterval, priceDropMagnitude);
    }

    /**
     * @dev Get current price for the token sale based on dutch auction pricing mechanics
     * @param presalePurchasePrice The price of the token during the presale interval.
     * @param startPrice The starting price of the token during the public sale.
     */
    function getCurrentPrice(uint256 presalePurchasePrice, uint256 startPrice) internal view returns (uint256) {
        if (_isPresale()) {
            return presalePurchasePrice;
        }
        uint256 timeElapsed = block.timestamp - publicSaleStartTime();
        uint256 discount = (timeElapsed / priceDropInterval) * priceDropMagnitude;
        if (discount > startPrice) {
            return minimumPrice;
        }
        uint256 currentPrice = startPrice - discount;
        return currentPrice > minimumPrice ? currentPrice : minimumPrice;
    }

    function publicSaleStartTime() public view returns (uint256) {
        return startTime + presaleInterval;
    }
}
