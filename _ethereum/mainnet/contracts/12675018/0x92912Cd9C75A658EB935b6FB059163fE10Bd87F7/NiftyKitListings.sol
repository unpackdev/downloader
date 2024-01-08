//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./NiftyKitBase.sol";
import "./ListingManager.sol";

contract NiftyKitListings is NiftyKitBase {
    using ListingManager for ListingManager.Listing;

    mapping(address => ListingManager.Listing) internal _collectionForListings;

    function setListing(
        address cAddress,
        uint256 tokenId,
        uint256 price
    ) public onlyAdmin {
        _collectionForListings[cAddress].set(tokenId, price);
    }

    function removeListing(address cAddress, uint256 tokenId) public onlyAdmin {
        require(_collectionForListings[cAddress].remove(tokenId));
    }

    function hasListing(address cAddress, uint256 tokenId)
        public
        view
        returns (bool)
    {
        return _collectionForListings[cAddress].has(tokenId);
    }

    function getPrice(address cAddress, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return _collectionForListings[cAddress].get(tokenId);
    }
}
