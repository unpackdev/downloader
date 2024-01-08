// SPDX-License-Identifier: No License

pragma solidity ^0.8.4;

interface IRarityspaceListing {
    // STRUCTS
    struct Listing {
        uint256 id;
        address owner;
        bytes32 dataHash;
    }

    // OWNER-ONLY
    function setWithdrawalWallet(address payable _withdrawalWallet) external;
    function setUpcomingFee(uint256 _upcomingFee) external;
    function setListingFee(uint256 _listingFee) external;
    function setFeaturedFee(uint256 _featuredFee) external;

    // VIEW
    function withdrawalWallet() external returns(address payable);
    function upcomingFee() external returns(uint256);
    function listingFee() external returns(uint256);
    function featuredFee() external returns(uint256);
    function totalListings() external returns(uint256);
    function listings(uint256) external returns(uint256, address, bytes32);

    // PUBLIC
    function createListing(bytes32 _dataHash) external payable returns (uint256);
    function createUpcoming(bytes32 _dataHash) external payable returns(uint256);
    function createListingFeatured(bytes32 _dataHash) external payable returns (uint256);
    function createUpcomingFeatured(bytes32 _dataHash) external payable returns(uint256);

    // EVENTS
    event CreatedUpcoming(Listing _listing);
    event CreatedListing(Listing _listing);
    event CreatedUpcomingFeatured(Listing _listing);
    event CreatedListingFeatured(Listing _listing);
    event UpcomingFeeChanged(uint256 _upcomingFee);
    event ListingFeeChanged(uint256 _listingFee);
    event FeaturedFeeChanged(uint256 _featuredFee);
    event WithdrawalWalletChanged(address _withdrawalWallet);
}