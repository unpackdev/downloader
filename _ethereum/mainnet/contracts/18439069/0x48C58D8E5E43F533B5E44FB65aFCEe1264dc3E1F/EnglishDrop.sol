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

import "./AccessControl.sol";
import "./IDropManager.sol";
import "./IEnglishDrop.sol";
import "./GrtLibrary.sol";

/// @title English Drop
/// @author Developed by Labrys on behalf of GRT Wines
/// @custom:contributor Sean L (slongdotexe)
/// @custom:contributor mfbevan (mfbevan.eth)
/// @custom:contributor Seb N
/// @notice A listing type involving a single token that can be bid on by multiple users, when a user is outbid they are refunded their bid.
///         The listing ends when the timer runs out and the highest bidder is the winner.
contract EnglishDrop is IEnglishDrop, AccessControl {
  bytes32 public constant override DROP_MANAGER_ROLE =
    keccak256("DROP_MANAGER_ROLE");

  /// Listing ID => Drop Listing
  mapping(uint128 => DropListing) public override listings;
  /// Token ID => Bid
  mapping(uint256 => Bid) public bids;
  /// Listing Id => Listing manually distributed
  mapping(uint128 => bool) public override listingDistributed;

  IDropManager public immutable dropManager;

  constructor(address _dropManager, address superUser) {
    GrtLibrary.checkZeroAddress(_dropManager, "dropManager");
    GrtLibrary.checkZeroAddress(superUser, "super user");

    dropManager = IDropManager(_dropManager);
    _grantRole(DROP_MANAGER_ROLE, _dropManager);
    _grantRole(DEFAULT_ADMIN_ROLE, superUser);
  }

  /// @dev Extend an auction by this amount of time if a bid has been placed within (endDate - bidExtensionTime) of an auction ending
  ///      This is to be defaulted at no extension time, with the option to add an extension time at a later date
  uint40 public override bidExtensionTime = 0 minutes;

  /// @dev Set listing details. To be used on creation and updating of listings
  /// @param listingId The id of the listing to update as per the global counter in the Drop Manager
  /// @param listing The new listing details
  function _setListing(
    uint128 listingId,
    Listing calldata listing,
    bytes calldata
  ) internal {
    if (
      block.timestamp > listing.endDate || listing.endDate <= listing.startDate
    ) {
      revert IncorrectParams(msg.sender);
    }

    listings[listingId] = DropListing(
      listing.releaseId,
      listing.startDate,
      listing.endDate,
      listing.minimumBid,
      listing.startingPrice
    );
  }

  function createListing(
    uint128 listingId,
    Listing calldata listing,
    bytes calldata data
  ) external override onlyRole(DROP_MANAGER_ROLE) {
    _setListing(listingId, listing, data);
    emit ListingCreated(listingId, listing.releaseId);
  }

  function updateListing(
    uint128 listingId,
    Listing calldata listing,
    bytes calldata data
  ) external override onlyRole(DROP_MANAGER_ROLE) notStarted(listingId) {
    _setListing(listingId, listing, data);
    emit ListingUpdated(listingId);
  }

  function deleteListing(
    uint128 listingId
  ) external override onlyRole(DROP_MANAGER_ROLE) notStarted(listingId) {
    delete listings[listingId];
    emit ListingDeleted(listingId);
  }

  function registerBid(
    uint128 listingId,
    uint256 tokenId,
    Bid calldata bid,
    bytes calldata
  ) external override onlyRole(DROP_MANAGER_ROLE) {
    DropListing memory listing = listings[listingId];
    Bid memory currentBid = bids[tokenId];
    if (
      !(block.timestamp > listing.startDate) ||
      block.timestamp > listing.endDate
    ) {
      revert ListingNotActive();
    }

    if (currentBid.amount == 0) {
      if (bid.amount < listing.startingPrice) {
        revert InvalidBid();
      }
    } else {
      if (bid.amount < currentBid.amount + listing.minimumBid) {
        revert InvalidBid();
      }
    }
    bids[tokenId] = bid;
    emit BidRegistered(bid.bidder, bid.amount, tokenId, listingId);

    if (block.timestamp + bidExtensionTime > listing.endDate) {
      listing.endDate += bidExtensionTime;
      listings[listingId] = listing;
      emit BiddingExtended(listingId);
    }
    if (currentBid.amount > 0) {
      dropManager.transferBaseToken(
        1,
        listingId,
        currentBid.bidder,
        currentBid.amount
      );
    }
  }

  function validateTokenClaim(
    uint128 listingId,
    uint128 releaseId,
    uint128 tokenId,
    address claimant
  )
    external
    view
    override
    onlyRole(DROP_MANAGER_ROLE)
    returns (uint256 salePrice)
  {
    DropListing memory listing = listings[listingId];

    if (
      !(block.timestamp > listing.endDate) ||
      listing.releaseId != releaseId ||
      claimant != bids[tokenId].bidder
    ) {
      revert InvalidClaim();
    }
    if (listingDistributed[listingId]) {
      return 0;
    }
    return bids[tokenId].amount;
  }

  function validateManualDistribution(
    uint128 listingId
  ) external returns (bool valid) {
    if (!listingEnded(listingId)) {
      revert InvalidClaim();
    }
    if (listingDistributed[listingId]) {
      revert AlreadyDistributed(listingId);
    }

    listingDistributed[listingId] = true;
    return true;
  }

  function listingEnded(
    uint128 listingId
  ) public view override returns (bool status) {
    DropListing memory currentListing = listings[listingId];
    if (currentListing.releaseId == 0) {
      revert NotListedHere();
    }
    status = block.timestamp > currentListing.endDate;
  }

  function setBidExtensionTime(
    uint40 time
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    bidExtensionTime = time;
  }

  modifier notStarted(uint128 listingId) {
    if (block.timestamp > listings[listingId].startDate) {
      revert ListingActive();
    }
    _;
  }
}
