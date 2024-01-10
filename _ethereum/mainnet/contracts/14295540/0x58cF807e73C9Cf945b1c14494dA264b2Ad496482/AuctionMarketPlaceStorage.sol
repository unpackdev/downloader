pragma solidity ^ 0.8.9;

import "./NFTation.sol";


contract AuctionMarketPlaceStorage {

    // +STRUCTS ------------------------------------------------
    struct Auction {
        uint256 startedAt;
        uint256 minBidPrice;
        address seller;
        uint256 lastBidAmount;
        address lastBidBidder;
        uint256 lastBidAt;
        bool hasBid; // whene first bid placed on auction this item change to true.
        bool initiated; // whene an auction created, this item change to true and never change again until delete whole auction.
    }
    // -STRUCTS -------------------------------------------------

    NFTation                    internal NFTationContract;
    uint256                     internal marketPlaceShare;
    mapping(uint256 => Auction) internal auctionMapping;

    uint256 internal auctionDuration ;
    uint256 internal auctionExtendDuration ;

    mapping(uint256 =>  mapping (address => uint256)) internal pendingWidthrawMapping;

    uint256[44] private __gap;

}