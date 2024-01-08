//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./NiftyKitListings.sol";
import "./NiftyKitOffers.sol";
import "./NiftyKitCollection.sol";

contract NiftyKitStorefront is NiftyKitListings, NiftyKitOffers {
    using ListingManager for ListingManager.Listing;
    using OfferManager for OfferManager.Offer;

    event ListingSold(
        address indexed cAddress,
        uint256 indexed tokenId,
        address indexed customer,
        uint256 price
    );
    event OfferAccepted(
        address indexed cAddress,
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 amount
    );

    function purchaseListing(address cAddress, uint256 tokenId) public payable {
        require(hasListing(cAddress, tokenId));
        require(_collectionForListings[cAddress].get(tokenId) == msg.value);

        NiftyKitCollection collection = NiftyKitCollection(cAddress);
        address creator = collection.ownerOf(tokenId);

        // split commission
        uint256 commission = _commissionValue(_commission, msg.value);
        payable(_treasury).transfer(commission);

        // split with collection
        uint256 cCommission =
            _commissionValue(collection.getCommission(), msg.value);
        if (cCommission > 0) {
            payable(collection.owner()).transfer(cCommission);
        }

        // calculate sales value
        payable(creator).transfer(msg.value - commission - cCommission);

        // transfer token to buyer
        collection.transfer(creator, _msgSender(), tokenId);

        // remove listing
        _collectionForListings[cAddress].remove(tokenId);

        // remove offer
        if (hasOffer(cAddress, tokenId)) {
            _removeOffer(cAddress, tokenId, true);
        }

        emit ListingSold(cAddress, tokenId, _msgSender(), msg.value);
    }

    function acceptOffer(address cAddress, uint256 tokenId) public onlyAdmin {
        require(hasOffer(cAddress, tokenId));
        address bidder = getHighestBidder(cAddress, tokenId);
        uint256 amount = getHighestAmount(cAddress, tokenId);
        NiftyKitCollection collection = NiftyKitCollection(cAddress);
        address creator = collection.ownerOf(tokenId);

        // split commission
        uint256 commission = _commissionValue(_commission, amount);
        payable(_treasury).transfer(commission);

        // split with collection
        uint256 cCommission =
            _commissionValue(collection.getCommission(), amount);
        if (cCommission > 0) {
            payable(collection.owner()).transfer(cCommission);
        }

        // calculate sales value
        payable(creator).transfer(amount - commission - cCommission);

        // transfer token to buyer
        collection.transfer(creator, bidder, tokenId);

        // remove offer
        removeOffer(cAddress, tokenId, false);

        // remove listing
        if (hasListing(cAddress, tokenId)) {
            removeListing(cAddress, tokenId);
        }

        emit OfferAccepted(cAddress, tokenId, bidder, amount);
    }

    function _commissionValue(uint256 commission, uint256 amount)
        private
        pure
        returns (uint256)
    {
        return (commission * amount) / 10000;
    }
}
