// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Gnar Auction Houses

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

pragma solidity 0.8.6;

interface ISkateContractV2AuctionHouse {
    struct Auction {
        // ID for the Gnar (ERC721 token ID)
        uint256 gnarId;
        // The current highest bid amount
        uint256 amount;
        // The timestamp the auction started
        uint256 startTimestamp;
        // The timestamp the auction is scheduled to end
        uint256 endTimestamp;
        // The address of the current highest bid
        address payable bidder;
        // Skate percentage
        uint8 skatePercent;
        // Dao percentage
        uint8 daoPercent;
        // Whether or not the auction has been settled
        bool settled;
    }

    event AuctionCreated(
        uint256 indexed gnarId,
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint256 timestamp
    );

    event AuctionBid(
        uint256 indexed gnarId,
        address sender,
        uint256 value,
        uint256 timestamp
    );

    event AuctionSettled(
        uint256 indexed gnarId,
        address winner,
        uint256 amount,
        uint256 timestamp
    );

    event AuctionReservePriceUpdated(uint256 reservePrice);

    event AuctionMinBidIncrementPercentageUpdated(
        uint256 minBidIncrementPercentage
    );

    event SkateDaoAddressesUpdated(address skate, address dao);

    function settleAuction() external;

    function settleCurrentAndCreateNewAuction() external;

    function createBid(
        uint256 gnarId,
        uint8 skatePercent,
        uint8 daoPercent
    ) external payable;

    function pause() external;

    function unpause() external;

    function setReservePrice(uint256 reservePrice) external;

    function setMinBidIncrementPercentage(uint8 minBidIncrementPercentage)
        external;

    function setSkateDaoAddresses(address skate, address dao) external;

    function remainingTime() external view returns (uint256);
}
