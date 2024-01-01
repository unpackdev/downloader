// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/*
  _______ .______     .___________.____    __    ____  __  .__   __.  _______     _______.
 /  _____||   _  \    |           |\   \  /  \  /   / |  | |  \ |  | |   ____|   /       |
|  |  __  |  |_)  |   `---|  |----` \   \/    \/   /  |  | |   \|  | |  |__     |   (----`
|  | |_ | |      /        |  |       \            /   |  | |  . `  | |   __|     \   \    
|  |__| | |  |\  \----.   |  |        \    /\    /    |  | |  |\   | |  |____.----)   |   
 \______| | _| `._____|   |__|         \__/  \__/     |__| |__| \__| |_______|_______/    
                                                                                     
*/

import "./IListing.sol";

/// @title English Drop
/// @author Developed by Labrys on behalf of GRT Wines
/// @custom:contributor Sean L (slongdotexe)
/// @custom:contributor mfbevan (mfbevan.eth)
/// @custom:contributor Seb N
/// @notice A listing type involving a single token that can be bid on by multiple users, when a user is outbid they are refunded their bid.
///         The listing ends when the timer runs out and the highest bidder is the winner.
interface IEnglishDrop is IListing {
  //################
  //#### STRUCTS ####

  /// @dev Parameters for storing Drop information for a given release
  /// @param releaseId The identifier of the DropListing - provided by the DropManager
  /// @param startDate Start date/time (Unix time)
  /// @param endDate End date/time (Unix time)
  /// @param minimumBid Minimum value a bid must be over the existing highest bid
  /// @param startingPrice Floor price for listing items
  struct DropListing {
    uint128 releaseId;
    uint40 startDate;
    uint40 endDate;
    uint256 minimumBid;
    uint256 startingPrice;
  }
  //################
  //#### ERRORS ####

  //Thrown if {endDate} is in the past or {startDate} is after end date
  error IncorrectParams(address sender);

  //#################
  //#### SETTERS ####

  /// @notice Set the time to extended a listing by if the bid has less than `bidExtensionTime` remaining
  /// @dev requires DEFAULT_ADMIN_ROLE
  function setBidExtensionTime(uint40 time) external;

  //#################
  //#### GETTERS ####

  /// Listing ID => {DropListing}
  function listings(uint128 listingId)
    external
    returns (
      uint128 releaseId,
      uint40 startDate,
      uint40 endDate,
      uint256 minimumBid,
      uint256 startingPrice
    );

  /// Listing ID => Has this listing been manually distributed
  function listingDistributed(uint128 listingId)
    external
    returns (bool withdrawn);

  /// Token ID => {Bid}
  function bids(uint256 tokenId)
    external
    returns (address bidder, uint256 amount);

  /// @notice If a bid has less than `bidExtensionTime` remaining when a bid is placed, it
  ///         will be extended by this amount
  /// @dev This can be set by users with the DEFAULT_ADMIN_ROLE using `setBidExtensionTime`
  function bidExtensionTime() external view returns (uint40 time);
}
