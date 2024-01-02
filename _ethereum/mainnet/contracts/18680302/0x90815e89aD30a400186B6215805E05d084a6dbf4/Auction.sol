// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract AuctionContract {
    struct Auction {
        uint256 auctionId;
        uint256 tokenId;
        uint256 startPrice;
        uint256 endTimestamp;
        address payable highestBidder;
        uint256 highestBid;
        bool ended;
    }

    mapping(uint256 => Auction) public auctions;
    uint256 public auctionIdCounter;
    uint256 public auctionDuration = 86400; // 24 hours (24 hours * 60 minutes * 60 seconds = 86400 seconds).
    uint256 public ownerPercentFees = 2; // 2% for the contract owner

    event AuctionStarted(uint256 auctionId, uint256 tokenId, uint256 startPrice, uint256 endTimestamp);
    event AuctionEnded(uint256 auctionId, uint256 tokenId, uint256 highestBid);

    constructor() {auctionIdCounter = 0;}

    function createAuction(uint256 _tokenId, uint256 _startPrice) public virtual;

    function placeBid(uint256 _auctionId) public payable virtual;

    function endAuction(uint256 _auctionId) public virtual;
}
