// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Noun Auction Houses

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

interface IAuctionHouse {
    struct Auction {
        // ID for the snoop DAO NFT (ERC721 token ID)
        uint256 snoopDAONFTId;
        // The current highest bid amount
        uint256 amount;
        // The time that the auction started
        uint256 startTime;
        // The time that the auction is scheduled to end
        uint256 endTime;
        // The address of the current highest bid
        address bidder;
        // Whether or not the auction has been settled
        bool settled;
    }

    event AuctionCreated(
        uint256 indexed snoopDAONFTId,
        uint256 startTime,
        uint256 endTime
    );

    event AuctionBid(
        uint256 indexed snoopDAONFTId,
        address sender,
        uint256 value,
        bool extended
    );

    event AuctionExtended(uint256 indexed snoopDAONFTId, uint256 endTime);

    event AuctionSettled(
        uint256 indexed snoopDAONFTId,
        address winner,
        uint256 amount
    );

    event AuctionTimeBufferUpdated(uint256 timeBuffer);

    event AuctionReservePriceUpdated(uint256 reservePrice);

    event AuctionDurationUpdated(uint256 duration);

    event AuctionMinBidIncrementPercentageUpdated(
        uint256 minBidIncrementPercentage
    );

    function settleAuction() external;

    function settleCurrentAndCreateNewAuction() external;

    function createBid(uint256 snoopDAONFTId, uint256 amount) external;

    function pause() external;

    function unpause() external;

    function setTimeBuffer(uint256 timeBuffer) external;

    function setReservePrice(uint256 reservePrice) external;

    function setDuration(uint256 duration) external;

    function setMinBidIncrementPercentage(uint8 minBidIncrementPercentage)
        external;
}
