//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./NiftyKitBase.sol";
import "./OfferManager.sol";

contract NiftyKitOffers is NiftyKitBase {
    using OfferManager for OfferManager.Offer;

    mapping(address => OfferManager.Offer) internal _collectionForOffers;

    function addOffer(address cAddress, uint256 tokenId) public payable {
        bool hasBid = hasOffer(cAddress, tokenId);
        address bidder = getHighestBidder(cAddress, tokenId);
        uint256 amount = getHighestAmount(cAddress, tokenId);

        require(
            _collectionForOffers[cAddress].add(_msgSender(), tokenId, msg.value)
        );

        // refund the previous amount
        if (hasBid) {
            payable(bidder).transfer(amount);
        }
    }

    function removeOffer(address cAddress, uint256 tokenId, bool refund) public onlyAdmin {
        require(hasOffer(cAddress, tokenId));
        _removeOffer(cAddress, tokenId, refund);
    }

    function hasOffer(address cAddress, uint256 tokenId)
        public
        view
        returns (bool)
    {
        return _collectionForOffers[cAddress].has(tokenId);
    }

    function getHighestAmount(address cAddress, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return _collectionForOffers[cAddress].highestAmount(tokenId);
    }

    function getHighestBidder(address cAddress, uint256 tokenId)
        public
        view
        returns (address)
    {
        return _collectionForOffers[cAddress].highestBidder(tokenId);
    }

    function _removeOffer(address cAddress, uint256 tokenId, bool refund) internal {
        address bidder = getHighestBidder(cAddress, tokenId);
        uint256 amount = getHighestAmount(cAddress, tokenId);
        _collectionForOffers[cAddress].remove(tokenId);
        if (refund) {
            payable(bidder).transfer(amount);
        }
    }
}
