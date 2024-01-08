// SPDX-License-Identifier: No License

pragma solidity ^0.8.4;

import "./IRarityspaceListing.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract RarityspaceListing is IRarityspaceListing, Ownable {
    using SafeMath for uint256;

    address payable public override withdrawalWallet;
    uint256 public override upcomingFee;
    uint256 public override listingFee;
    uint256 public override featuredFee;

    uint256 public override totalListings = 0;

    mapping(uint256 => Listing) public override listings;

    constructor(address payable _withdrawalWallet) {
        setWithdrawalWallet(_withdrawalWallet);
        setUpcomingFee(0.1 ether);
        setListingFee(1 ether);
        setFeaturedFee(0.1 ether);
    }

    function setWithdrawalWallet(address payable _withdrawalWallet) public override onlyOwner {
        withdrawalWallet = _withdrawalWallet;
        emit WithdrawalWalletChanged(withdrawalWallet);
    }

    function setUpcomingFee(uint256 _upcomingFee) public override onlyOwner {
        upcomingFee = _upcomingFee;
        emit UpcomingFeeChanged(upcomingFee);
    }

    function setListingFee(uint256 _listingFee) public override onlyOwner {
        listingFee = _listingFee;
        emit ListingFeeChanged(listingFee);
    }

    function setFeaturedFee(uint256 _featuredFee) public override onlyOwner {
        featuredFee = _featuredFee;
        emit FeaturedFeeChanged(featuredFee);
    }

    function createListing(bytes32 _dataHash) external override payable returns (uint256) {
        if (msg.sender != owner()) {
            require(msg.value == listingFee, "Rarityspace:createListing:: Insufficient funds.");
        }

        uint256 id = totalListings;
        Listing memory listing = Listing(id, msg.sender, _dataHash);
        listings[id] = listing;

        totalListings = totalListings.add(1);
        emit CreatedListing(listing);
        
        _withdraw();
        return id;
    }

    function createUpcoming(bytes32 _dataHash) external override payable returns (uint256) {
        if (msg.sender != owner()) {
            require(msg.value == upcomingFee, "Rarityspace:updateListing:: Insufficient funds.");
        }

        uint256 id = totalListings;
        Listing memory listing = Listing(id, msg.sender, _dataHash);
        listings[id] = listing;

        totalListings = totalListings.add(1);
        emit CreatedUpcoming(listing);

        _withdraw();
        return id;
    }

    function createListingFeatured(bytes32 _dataHash) external override payable returns (uint256) {
        if (msg.sender != owner()) {
            require(msg.value == listingFee.add(featuredFee), "Rarityspace:createListing:: Insufficient funds.");
        }
        
        uint256 id = totalListings;
        Listing memory listing = Listing(id, msg.sender, _dataHash);
        listings[id] = listing;

        totalListings = totalListings.add(1);
        emit CreatedListingFeatured(listing);
        
        _withdraw();
        return id;
    }

    function createUpcomingFeatured(bytes32 _dataHash) external override payable returns (uint256) {
        if (msg.sender != owner()) {
            require(msg.value == upcomingFee.add(featuredFee), "Rarityspace:updateListing:: Insufficient funds.");
        }
        
        uint256 id = totalListings;
        Listing memory listing = Listing(id, msg.sender, _dataHash);
        listings[id] = listing;

        totalListings = totalListings.add(1);
        emit CreatedUpcomingFeatured(listing);

        _withdraw();
        return id;
    }

    function _withdraw() internal {
        withdrawalWallet.transfer(address(this).balance);
    }

    function withdraw() external onlyOwner {
        _withdraw();
    }

    receive() external payable{}
}