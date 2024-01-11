// SPDX-License-Identifier: GPL-3.0

/**
 * @title Interface for Auction Houses
 */

pragma solidity ^0.8.6;

// IAuctionHouse.sol is a modified version of Zora's IAuctionHouse.sol:
// https://github.com/ourzora/auction-house/blob/54a12ec1a6cf562e49f0a4917990474b11350a2d/contracts/interfaces/IAuctionHouse.sol

interface IAuctionHouse {
    struct Auction {
        // ID for the ERC721 token
        uint256 tokenId;
        // The current highest bid amount
        uint256 amount;
        // The time that the auction started
        uint256 startTime;
        // The time that the auction is scheduled to end
        uint256 endTime;
        // The address that should receive the funds once the NFT is sold.
        address tokenOwner;
        // The address of the current highest bid
        address payable bidder;
        // Whether or not the auction has been settled
        bool settled;
    }

    event AuctionCreated(uint256 indexed tokenId, uint256 startTime, uint256 endTime);
    event AuctionBid(uint256 indexed tokenId, address sender, uint256 value, bool extended);
    event AuctionExtended(uint256 indexed tokenId, uint256 endTime);
    event AuctionSettled(uint256 indexed tokenId, address winner, uint256 amount);
    event AuctionTimeBufferUpdated(uint256 timeBuffer);
    event AuctionReservePriceUpdated(uint256 reservePrice);
    event AuctionMinBidIncrementUpdated(uint256 minBidIncrement);
    event AuctionRemoved(uint256 indexed tokenId);

    function settleAuction(uint256 tokenId) external;

    function currentAuction() external view returns (Auction memory auction);

    function createBid(uint256 tokenId) external payable;

    function setTimeBuffer(uint256 timeBuffer) external;

    function setReservePrice(uint256 reservePrice) external;

    function setMinBidIncrement(uint256 minBidIncrement) external;
}
