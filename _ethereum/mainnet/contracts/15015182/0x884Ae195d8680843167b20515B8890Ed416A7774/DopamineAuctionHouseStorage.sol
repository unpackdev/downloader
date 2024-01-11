// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import "./IDopamineAuctionHouse.sol";
import "./IDopamineAuctionHouseToken.sol";

/// @title Dopamine Auction House Storage Contract
/// @dev Upgrades involving new storage variables should utilize a new contract
///  inheriting the prior storage contract. This would look like the following:
/// `contract DopamineAuctionHouseStorageV1 is DopamineAuctionHouseStorage {}`
/// `contract DopamineAuctionHouseStorageV2 is DopamineAuctionHouseStorageV1 {}`
contract DopamineAuctionHouseStorage {

    /// @notice Address of temporary admin that will become admin once accepted.
    address public pendingAdmin;

    /// @notice The address administering auctions and thus token emissions.
    address public admin;

    /// @notice The time window in seconds to extend bids that are placed within
    ///  `auctionBuffer` seconds from the auction's end time.
    uint256 public auctionBuffer;

    /// @notice The English auction starting reserve price.
    uint256 public reservePrice;

    /// @notice The percentage of auction revenue directed to the treasury.
    uint256 public treasurySplit;

    /// @notice The initial duration in seconds to allot for a single auction.
    uint256 public auctionDuration;

    /// @notice The address of the Dopamine treasury.
    address payable public treasury;

    /// @notice The address of the Dopamine reserve.
    address payable public reserve;

    /// @notice The Dopamine auction house ERC-721 token.
    IDopamineAuctionHouseToken public token;

    /// @notice The ongoing auction being run.
    IDopamineAuctionHouse.Auction public auction;

    /// @dev A uint marker for preventing reentrancy (locked = 1, unlocked = 2).
    uint256 internal _locked;

    /// @dev A boolean indicating whether or not the auction is suspended.
    uint256 internal _suspended;

}
