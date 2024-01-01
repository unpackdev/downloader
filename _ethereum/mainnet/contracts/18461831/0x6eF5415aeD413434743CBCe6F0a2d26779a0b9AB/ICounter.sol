// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICounter {
    function remainingInListing(
        uint256 listingID
    ) external view returns (uint256);

    function isListingFilled(uint256 listingID) external view returns (bool);

    function initListing(uint256 listingID, uint256 remainingEditions) external;

    function decreaseListing(uint256 listingID, uint256 selling) external;

    function remainingInOffer(uint256 offerID) external view returns (uint256);

    function isOfferFilled(uint256 offerID) external view returns (bool);

    function initOffer(uint256 offerID, uint256 remainingEditions) external;

    function decreaseOffer(uint256 offerID, uint256 selling) external;
}
