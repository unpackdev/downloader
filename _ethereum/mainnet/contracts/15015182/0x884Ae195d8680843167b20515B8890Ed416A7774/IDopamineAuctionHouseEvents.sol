// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Dopamine Auction House Events Interface
interface IDopamineAuctionHouseEvents {

    /// @notice Emits when a new auction is created.
    /// @param tokenId The id of the NFT put up for auction.
    /// @param startTime The timestamp in epoch seconds the auction was created.
    /// @param endTime The projected end time of the auction in epoch seconds.
    event AuctionCreated(
        uint256 indexed tokenId,
        uint256 startTime,
        uint256 endTime
    );

    /// @notice Emits when the auction for NFT `tokenId` is extended.
    /// @param tokenId The id of the NFT being auctioned.
    /// @param endTime The new auction end time as an epoch timestamp.
    event AuctionExtended(
        uint256 indexed tokenId,
        uint256 endTime
    );

    /// @notice Emits when auction for NFT of id `tokenId` is settled.
    /// @param tokenId The id of the NFT being auctioned.
    /// @param winner The address of the auction winner.
    /// @param amount The amount in wei the winner paid for the auction.
    event AuctionSettled(
        uint256 indexed tokenId,
        address winner,
        uint256 amount
    );

    /// @notice Emits when a new bid is placed for NFT of id `tokenId`.
    /// @param tokenId The id of the NFT being bid on.
    /// @param bidder The address which placed the bid.
    /// @param extended True if the bid triggered extension, False otherwise.
    event AuctionBid(
        uint256 indexed tokenId,
        address bidder,
        uint256 value,
        bool extended
    );

    /// @notice Emits when auction creation fails (due to NFT mint reverting).
    event AuctionCreationFailed();

    /// @notice Emits when a refund fails for bidder `bidder`.
    /// @param bidder The address of the bidder which does not accept payments.
    event RefundFailed(address bidder);

    /// @notice Emits when the auction is suspended.
    event AuctionSuspended();

    /// @notice Emits when the auction is unpaused.
    event AuctionResumed();

    /// @notice Emits when a new auctionbuffer `auctionBuffer` is set.
    /// @param auctionBuffer The new auction buffer to set, in seconds.
    event AuctionBufferSet(uint256 auctionBuffer);

    /// @notice Emits when a new auction reserve price, `reservePrice` is set.
    /// @param reservePrice The new auction reserve price in wei.
    event AuctionReservePriceSet(uint256 reservePrice);

    /// @notice Emits when a new auction treasury split `treasurySplit` is set.
    /// @param treasurySplit The percentage of auction revenue sent to treasury.
    event AuctionTreasurySplitSet(uint256 treasurySplit);

    /// @notice Emits when a new auction duration `auctionDuration` is set.
    /// @param auctionDuration The time in seconds an auction will run for.
    event AuctionDurationSet(uint256 auctionDuration);

    /// @notice Emits when a new pending admin `pendingAdmin` is set.
    /// @param pendingAdmin The new address of the pending admin that was set.
    event PendingAdminSet(address indexed pendingAdmin);

    /// @notice Emits when a new treasury address `treasury` is set.
    /// @param treasury The new address of the treasury that was set.
    event TreasurySet(address indexed treasury);

    /// @notice Emits when a new reserve address `reserve` is set.
    /// @param reserve The new address of the reserve that was set.
    event ReserveSet(address indexed reserve);

}
