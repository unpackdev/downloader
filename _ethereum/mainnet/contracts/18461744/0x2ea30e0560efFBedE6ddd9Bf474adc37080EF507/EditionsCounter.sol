// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Ownable.sol";

import "./ICounter.sol";

error NotAMarketplace();
error EditionsCantBeZero();

contract EditionsCounter is Ownable, ICounter {
    address marketplace;

    mapping(uint256 => uint256) public override remainingInListing;
    mapping(uint256 => bool) public override isListingFilled;

    mapping(uint256 => uint256) public override remainingInOffer;
    mapping(uint256 => bool) public override isOfferFilled;

    modifier onlyMarketplace() {
        if (msg.sender != marketplace) revert NotAMarketplace();

        _;
    }

    function initListing(
        uint256 listingID,
        uint256 allEditions
    ) external override onlyMarketplace {
        if (allEditions == 0) revert EditionsCantBeZero();
        remainingInListing[listingID] = allEditions;
    }

    function decreaseListing(
        uint256 listingID,
        uint256 selling
    ) external override onlyMarketplace {
        remainingInListing[listingID] -= selling;

        if (remainingInListing[listingID] == 0)
            isListingFilled[listingID] = true;
    }

    function initOffer(
        uint256 offerID,
        uint256 allEditions
    ) external override onlyMarketplace {
        if (allEditions == 0) revert EditionsCantBeZero();
        remainingInOffer[offerID] = allEditions;
    }

    function decreaseOffer(
        uint256 offerID,
        uint256 selling
    ) external override onlyMarketplace {
        remainingInOffer[offerID] -= selling;

        if (remainingInOffer[offerID] == 0) isOfferFilled[offerID] = true;
    }

    function setMarketplace(address newMarketplace) external onlyOwner {
        marketplace = newMarketplace;
    }
}
