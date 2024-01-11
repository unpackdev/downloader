// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Sunrise Auction Houses

pragma solidity ^0.8.6;

interface ISunriseAuctionHouse {
    struct Auction {
        // ID for the Sunrise (ERC721 token ID)
        uint256 sunriseId;
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
        // The auction duration
        uint256 duration;
    }

    event AuctionCreated(uint256 indexed sunriseId, uint256 startTime, uint256 endTime);

    event AuctionBid(uint256 indexed sunriseId, address sender, uint256 value, bool extended);

    event AuctionExtended(uint256 indexed sunriseId, uint256 endTime);

    event AuctionSettled(uint256 indexed sunriseId, address winner, uint256 amount);

    event AuctionTimeBufferUpdated(uint256 timeBuffer);

    event AuctionReservePriceUpdated(uint256 reservePrice);

    event AuctionMinBidIncrementPercentageUpdated(uint256 minBidIncrementPercentage);

    event AuctionDurationUpdated(uint256 duration);

    function settleAuction() external;

    function settleCurrentAndCreateNewAuction() external;

    function createBid(uint256 sunriseId) external payable;

    function pause() external;

    function unpause() external;

    function setTimeBuffer(uint256 timeBuffer) external;

    function setReservePrice(uint256 reservePrice) external;

    function setMinBidIncrementPercentage(uint8 minBidIncrementPercentage) external;

    function setDuration(uint256 duration) external;
}
