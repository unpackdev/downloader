// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Orbits Auction Houses

pragma solidity ^0.8.6;

interface IOrbitsAuction{
    struct Auction {
        // ID for the Orbit (ERC721 token ID)
        uint256 orbitId;
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

    event AuctionCreated(uint256 indexed orbitId, uint256 startTime, uint256 endTime);

    event AuctionBid(uint256 indexed orbitId, address sender, uint256 value, bool extended);

    event AuctionExtended(uint256 indexed orbitId, uint256 endTime);

    event AuctionSettled(uint256 indexed orbitId, address winner, uint256 amount);

    event AuctionTimeBufferUpdated(uint256 timeBuffer);

    event AuctionReservePriceUpdated(uint256 reservePrice);

    event AuctionMinBidIncrementPercentageUpdated(uint256 minBidIncrementPercentage);

    event WhitelistStatusChanged(bool whitelistStatus);

    event DurationUpdated(uint256 duration);

    function settleAuction() external;

    function createAuction(string calldata) external;

    function createBid(uint256 orbitId) external payable;

    function pause() external;

    function unpause() external;

    function setTimeBuffer(uint256 timeBuffer) external;

    function setReservePrice(uint256 reservePrice) external;

    function setMinBidIncrementPercentage(uint8 minBidIncrementPercentage) external;

    function setWhitelistStatus(bool whitelistStatus) external;

    function setDuration(uint256 duration) external;

    function addToWhitelist(address[] calldata addresses) external;

    function removeFromWhitelist(address[] calldata addresses) external;

    function alterWhitelist(address[] calldata addresses, bool[] calldata statuses) external;
}