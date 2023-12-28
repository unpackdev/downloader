// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @dev Auction struct
/// @param seller The seller of the token
/// @param payoutReceiver The address that receives any payout from the auction
/// @param currencyAddress The currency address - Zero address == ETH
/// @param highestBidder The highest bidder address
/// @param highestBid The highest bid
/// @param reservePrice The reserve price of the auction
/// @param auctionOpenTime The timestamp at which bidding is allowed
/// @param startTime The timestamp at which the auction was kicked off with a bid
/// @param duration The duration the auction should last after it is started
struct Auction {
    address seller;
    address payoutReceiver;
    address currencyAddress;
    address highestBidder;
    uint256 highestBid;
    uint256 reservePrice;
    uint256 auctionOpenTime;
    uint256 startTime;
    uint256 duration;
}

/// @dev Sale struct
/// @param seller The seller of the token
/// @param payoutReceiver The address that receives any payout from the auction
/// @param currencyAddress The currency address - Zero address == ETH
/// @param price The price for the nft
struct Sale {
    address seller;
    address payoutReceiver;
    address currencyAddress;
    uint256 price;
    uint256 saleOpenTime;
}

interface ITLAuctionHouseEvents {
    event RoyaltyEngineUpdated(address indexed prevRoyaltyEngine, address indexed newRoyaltyEngine);
    event WethUpdated(address indexed prevWeth, address indexed newWeth);
    event MinBidIncreaseUpdated(uint256 indexed newMinBidIncreasePerc, uint256 indexed newMinBidIncreaseLimit);
    event ProtocolFeeUpdated(
        address indexed newProtocolFeeReceiver, uint256 indexed newProtocolFeePerc, uint256 indexed newProtocolFeeLimit
    );

    event AuctionConfigured(
        address indexed sender, address indexed nftAddress, uint256 indexed tokenId, Auction auction
    );
    event AuctionCanceled(address indexed sender, address indexed nftAddress, uint256 indexed tokenId);
    event AuctionSettled(address indexed sender, address indexed nftAddress, uint256 indexed tokenId, Auction auction);
    event AuctionBid(address indexed sender, address indexed nftAddress, uint256 indexed tokenId, Auction auction);

    event SaleConfigured(address indexed sender, address indexed nftAddress, uint256 indexed tokenId, Sale sale);
    event SaleCanceled(address indexed sender, address indexed nftAddress, uint256 indexed tokenId);
    event SaleFulfilled(address indexed sender, address indexed nftAddress, uint256 indexed tokenId, Sale sale);
}
