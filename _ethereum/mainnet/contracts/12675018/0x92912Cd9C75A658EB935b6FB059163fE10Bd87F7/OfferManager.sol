//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

library OfferManager {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Offer {
        EnumerableSet.UintSet _tokenIdsWithOffers;
        mapping(uint256 => uint256) _tokensForHighestAmount;
        mapping(uint256 => address) _tokensForHighestBidder;
    }

    function add(
        Offer storage offer,
        address bidder,
        uint256 tokenId,
        uint256 amount
    ) internal returns (bool) {
        if (!has(offer, tokenId)) {
            offer._tokenIdsWithOffers.add(tokenId);
            offer._tokensForHighestBidder[tokenId] = bidder;
            offer._tokensForHighestAmount[tokenId] = amount;
            return true;
        } else if (amount > highestAmount(offer, tokenId)) {
            offer._tokensForHighestBidder[tokenId] = bidder;
            offer._tokensForHighestAmount[tokenId] = amount;
            return true;
        }
        return false;
    }

    function remove(Offer storage offer, uint256 tokenId)
        internal
        returns (bool)
    {
        if (has(offer, tokenId)) {
            offer._tokenIdsWithOffers.remove(tokenId);
            delete offer._tokensForHighestBidder[tokenId];
            delete offer._tokensForHighestAmount[tokenId];
            return true;
        }
        return false;
    }

    function has(Offer storage offer, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        return offer._tokenIdsWithOffers.contains(tokenId);
    }

    function highestAmount(Offer storage offer, uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        return offer._tokensForHighestAmount[tokenId];
    }

    function highestBidder(Offer storage offer, uint256 tokenId)
        internal
        view
        returns (address)
    {
        return offer._tokensForHighestBidder[tokenId];
    }
}
