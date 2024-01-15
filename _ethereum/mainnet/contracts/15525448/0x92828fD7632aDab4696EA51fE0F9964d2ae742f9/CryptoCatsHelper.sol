pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// CryptoCatsHelper v0.9.0 debug 3
//
// https://github.com/bokkypoobah/TokenToolz
//
// Deployed to Mainnet 0x92828fD7632aDab4696EA51fE0F9964d2ae742f9
//
// SPDX-License-Identifier: MIT
//
// Enjoy.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd 2022. The MIT Licence.
// ----------------------------------------------------------------------------

// CryptoCatsMarkets @ 0x088C6Ad962812b5Aa905BA6F3c5c145f9D4C079f
interface CryptoCatsMarkets {
    struct Offer {
        bool isForSale;
        uint catIndex;
        address seller;
        uint minPrice;
        address sellOnlyTo;
    }

    function catIndexToAddress(uint256 catId) external view returns (address owner);
    function catAttributes(uint256 catId) external view returns (string[6] memory attributes);
    function catsForSale(uint256 catId) external view returns (Offer memory offer);
}


contract CryptoCatsHelper {
    function getCatData(CryptoCatsMarkets cryptoCatsMarket, uint[] memory catIds) public view returns (
        address[] memory owners,
        string[6][] memory attributes,
        CryptoCatsMarkets.Offer[] memory offers
    ) {
        uint length = catIds.length;
        owners = new address[](length);
        attributes = new string[6][](length);
        offers = new CryptoCatsMarkets.Offer[](length);
        for (uint i = 0; i < length;) {
            owners[i] = cryptoCatsMarket.catIndexToAddress(i);
            // attributes[i] = cryptoCatsMarket.catAttributes(i);
            offers[i] = cryptoCatsMarket.catsForSale(i);
            unchecked {
                i++;
            }
        }
    }
}