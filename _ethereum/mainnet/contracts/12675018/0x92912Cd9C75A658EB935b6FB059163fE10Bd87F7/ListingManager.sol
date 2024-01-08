//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

library ListingManager {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Listing {
        EnumerableSet.UintSet _forSaleTokenIds;
        mapping(uint256 => uint256) _tokensForPrices;
    }

    function set(
        Listing storage listing,
        uint256 tokenId,
        uint256 price
    ) internal {
        if (!has(listing, tokenId)) {
            listing._forSaleTokenIds.add(tokenId);
        }
        listing._tokensForPrices[tokenId] = price;
    }

    function remove(Listing storage listing, uint256 tokenId)
        internal
        returns (bool)
    {
        if (has(listing, tokenId)) {
            listing._forSaleTokenIds.remove(tokenId);
            delete listing._tokensForPrices[tokenId];
            return true;
        }
        return false;
    }

    function has(Listing storage listing, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        return listing._forSaleTokenIds.contains(tokenId);
    }

    function get(Listing storage listing, uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        return listing._tokensForPrices[tokenId];
    }
}
