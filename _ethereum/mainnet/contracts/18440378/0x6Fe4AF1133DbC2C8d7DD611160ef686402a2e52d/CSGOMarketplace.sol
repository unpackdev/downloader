// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CSGOMarketplace {
    address public owner;

    struct Listing {
        address buyer;
        string market_name;
        uint256 price;
        bool isSold;
        bool isCompleted;
    }

    mapping(uint256 => Listing) public listings;
    uint256 public latestListingId; // New state variable to keep track of the latest listing ID

    event ListingCreated(uint256 indexed id, address indexed seller);
    event ListingSold(uint256 indexed id, address indexed buyer, uint256 price);
    event FundsReleased(uint256 indexed id, address indexed seller, uint256 price);
    event FundsReturned(uint256 indexed id, address indexed buyer, uint256 price);

    constructor() {
        owner = msg.sender;
        latestListingId = 0; // Initialize the latestListingId to 0 (or any other starting value)
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function purchaseListing(uint256 price, string memory market_name) external payable {
        address _buyer = msg.sender;
        
        // Increment the latestListingId before using it
        latestListingId++;
        uint256 listingId = latestListingId;

        Listing storage listing = listings[listingId];
        require(!listing.isSold, "Listing already sold");
        require(!listing.isCompleted, "Listing already completed");
        require(msg.value == price, "Incorrect payment amount"); // Ensure the sent value matches the listing price

        listing.isSold = true;
        listing.price = price;
        listing.buyer = msg.sender;
        listing.market_name = market_name; // Update the market_name field

        listings[listingId] = listing; // Update the listing in the mapping

        emit ListingCreated(listingId, _buyer);
        emit ListingSold(listingId, msg.sender, price); // Use the correct listingId here
    }


    function releaseFunds(uint256 _listingId, address payable seller) external onlyOwner {
        Listing storage listing = listings[_listingId];

        require(seller != address(0), "Invalid seller wallet address");
        require(listing.isSold, "Listing not sold");
        require(!listing.isCompleted, "Listing already completed");
        require(listing.price > 0, "No price available");

        uint256 feeAmount = (listing.price * 4) / 100;
        seller.transfer(listing.price - feeAmount);
        payable(0xA7F2FD4367674b1f0A48E6803Be32397e16a5f3F).transfer(feeAmount);

        listing.isCompleted = true;

        emit FundsReleased(_listingId, seller, listing.price);
    }

    function returnToBuyer(uint256 _listingId) external onlyOwner {
        Listing storage listing = listings[_listingId];

        require(listing.price > 0, "No price available");
        require(!listing.isCompleted, "Listing already completed");

        address payable buyer = payable(listing.buyer);
        uint256 priceToReturn = listing.price;
        buyer.transfer(listing.price);

        listing.isCompleted = true;
        listing.price = 0;

        emit FundsReturned(_listingId, buyer, priceToReturn); // Emit event to indicate the return of funds
    }
}