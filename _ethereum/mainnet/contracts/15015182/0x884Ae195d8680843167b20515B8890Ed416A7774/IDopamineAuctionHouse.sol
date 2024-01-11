// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import "./IDopamineAuctionHouseEvents.sol";

/// @title Dopamine DAO Auction House Interface
interface IDopamineAuctionHouse is IDopamineAuctionHouseEvents {

    /// @notice Auction struct that encapsulates the ongoing English auction.
    struct Auction {

        /// @notice The id of the NFT being auctioned.
        uint256 tokenId;

        /// @notice The highest bid in wei placed so far for the auction.
        uint256 amount;

        /// @notice The epoch timestamp at which the auction started.
        uint256 startTime;

        /// @notice The epoch timestamp projected for the auction to end.
        uint256 endTime;

        /// @notice The address of the bidder with the highest bid so far.
        address payable bidder;

        /// @notice A boolean indicating whether the auction has been settled.
        bool settled;
    }

    /// @notice Indicates whether new auctions are suspened or not.
    /// @return True if new auctions are suspended, False otherwise.
    function suspended() external view returns (bool);

    /// @notice Suspends new auctions from being created.
    /// @dev Reverts if not called by admin or auctions are already suspended.
    ///  Note that suspension does not interfere with the ongoing auction.
    function suspendNewAuctions() external;

    /// @notice Resumes creation of new auctions.
    /// @dev Reverts if not called by admin or auctions are already live.
    ///  If the existing auction has already settled, then a new auction will
    ///  be created. If minting on creation fails, the auction stays suspended.
    function resumeNewAuctions() external;

    /// @notice Settles ongoing auction and creates a new one if unsuspended.
    /// @dev Throws if current auction ongoing or already settled. 2 scenarios:
    ///  [Suspended]:   Current auction settles.
    ///  [Unsuspended]: Current auction settles, and a new auction is created.
    ///  If in the latter case creation fails, new auctions will be suspended.
    function settleAuction() external;

    /// @notice Place a bid for the current NFT being auctioned.
    /// @dev Reverts if invalid NFT specified, the auction has expired, or the
    ///  placed bid is not at least `MIN_BID_DIFF` % higher than the last bid.
    /// @param tokenId The identifier of the NFT currently being auctioned.
    function createBid(uint256 tokenId) external payable;

    /// @notice Sets a new pending admin `newPendingAdmin`.
    /// @dev This function throws if not called by the current admin.
    /// @param newPendingAdmin The address of the new pending admin.
    function setPendingAdmin(address newPendingAdmin) external;

    /// @notice Convert the current `pendingAdmin` to the new `admin`.
    /// @dev This function throws if not called by the current pending admin.
    function acceptAdmin() external;

    /// @notice Sets a new auctions bidding duration, `newAuctionDuration`.
    /// @dev This function is only callable by the admin, and throws if the
    ///  auction duration is set too low or too high.
    /// @param newAuctionDuration New auction duration to set, in seconds.
    function setAuctionDuration(uint256 newAuctionDuration) external;

    /// @notice Sets a new treasury split, `newTreasurySplit`.
    /// @dev This function is only callable by the admin, and throws if the
    ///  new treasury split is set to a percentage above 100%.
    /// @param newTreasurySplit The new treasury split to set, as a percentage.
    function setTreasurySplit(uint256 newTreasurySplit) external;

    /// @notice Sets a new auction time buffer, `newAuctionBuffer`.
    /// @dev This function is only callable by the admin and throws if the time
    ///  buffer is set too low or too high.
    /// @param newAuctionBuffer The time buffer to set, in seconds since epoch.
    function setAuctionBuffer(uint256 newAuctionBuffer) external;

    /// @notice Sets a new auction reserve price, `newReservePrice`.
    /// @dev This function is only callable by the admin and throws if the
    ///  auction reserve price is set too low or too high.
    /// @param newReservePrice The new reserve price to set, in wei.
    function setReservePrice(uint256 newReservePrice) external;

    /// @notice Sets the treasury address to `newTreasury`.
    /// @dev This function is only callable by the admin.
    /// @param newTreasury The new treasury address to set.
    function setTreasury(address payable newTreasury) external;

    /// @notice Sets the reserve address to `newReserve`.
    /// @dev This function is only callable by the admin.
    /// @param newReserve The new reserve address to set.
    function setReserve(address payable newReserve) external;

}
