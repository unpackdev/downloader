/*

  Abstract over fixed-price sales and Dutch auctions, with the intent of easily supporting additional methods of sale later.

  Separated into a library for convenience, all the functions are inlined.

*/
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;


/**
 * @title SaleKindLibrary
 * @author Project Wyvern Developers
 */
library SaleKindLibrary {
    /**
     * Side: buy or sell.
     */
    enum Side {
        Buy,
        Sell
    }

    /**
     * Currently supported kinds of sale: fixed price, Dutch auction.
     * English auctions cannot be supported without stronger escrow guarantees.
     * Future interesting options: Vickrey auction, nonlinear Dutch auctions.
     */
    enum SaleKind {
        FixedPrice,
        DutchAuction,
        EnglishAuction
    }

    /**
     * @dev Check whether the parameters of a sale are valid
     * @param saleKind Kind of sale
     * @param expirationTime Order expiration time
     * @return Whether the parameters were valid
     */
    function validateParameters(SaleKind saleKind, uint256 expirationTime)
        internal
        pure
        returns (bool)
    {
        /* Auctions must have a set expiration date. */
        return (saleKind == SaleKind.FixedPrice ||
                saleKind == SaleKind.EnglishAuction ||
               (saleKind == SaleKind.DutchAuction && expirationTime > 0));
    }

    /**
     * @dev Return whether or not an order can be settled
     * @dev Precondition: parameters have passed validateParameters
     * @param listingTime Order listing time
     * @param expirationTime Order expiration time
     */
    function canSettleOrder(uint256 listingTime, uint256 expirationTime)
        internal
        view
        returns (bool)
    {
        uint256 currentTime = block.timestamp;
        return
            (listingTime < currentTime) &&
            (expirationTime == 0 || currentTime < expirationTime);
    }

    /**
     * @dev Calculate the settlement price of an order
     * @dev Precondition: parameters have passed validateParameters.
     * @param side Order side
     * @param saleKind Method of sale
     * @param basePrice Order base price
     * @param extra Order extra price data
     * @param listingTime Order listing time
     * @param expirationTime Order expiration time
     */
    function calculateFinalPrice(
        Side side,
        SaleKind saleKind,
        uint256 basePrice,
        uint256 extra,
        uint256 listingTime,
        uint256 expirationTime
    ) internal view returns (uint256 finalPrice) {
        require(canSettleOrder(listingTime, expirationTime), "Invalid timestamps.");
        if (saleKind == SaleKind.DutchAuction) {
            uint256 diff = (extra * (block.timestamp - listingTime))/(expirationTime- listingTime);
            if (side == Side.Sell) {
                /* Sell-side - start price: basePrice. End price: basePrice - extra. */
                return basePrice - diff;
            } else {
                /* Buy-side - start price: basePrice. End price: basePrice + extra. */
                return basePrice + diff;
            }
        }
        return basePrice;
    }
}
