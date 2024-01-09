// SPDX-License-Identifier: GPL-3.0

/// @title Interface for YQC Auction Houses

pragma solidity ^0.8.6;

interface IYQCAuctionHouse {
    struct Auction {
        // ID for the Queen (ERC721 token ID)
        uint256 queenId;
        // The current highest bid amount
        uint256 amount;
        // The time that the auction started
        uint256 startTime;
        // The time that the auction is scheduled to end
        uint256 endTime;
        // The address of the current highest bid
        address payable bidder;
        // Whether or not the auction has been settled
        bool settled;
    }

    struct Bid {
        // The current highest bid amount
        uint256 amount;
        // The address of the current highest bid
        address payable bidder;
    }

    event AuctionCreated(uint256 indexed queenId, uint256 startTime, uint256 endTime);

    event AuctionBid(uint256 indexed queenId, address sender, uint256 value);

    event AuctionExtended(uint256 indexed queenId, uint256 endTime);

    event AuctionSettled(uint256 indexed queenId, address winner, uint256 amount);

    event AuctionTreasuryUpdated(address treasury);

    event AuctionReservePriceUpdated(uint256 reservePrice);

    event AuctionMinBidIncrementPercentageUpdated(uint256 minBidIncrementPercentage);

    function mintQueenersQueens(uint256[] memory queenIds) external;

    function settleAuction(uint256 queenId) external;

    function createBid(uint256 queenId) external payable;

    function pause() external;

    function unpause(uint256 timestamp) external;

    function setTreasury(address treasury) external;

    function setReservePrice(uint256 reservePrice) external;

    function setMinBidIncrementPercentage(uint8 minBidIncrementPercentage) external;
}
