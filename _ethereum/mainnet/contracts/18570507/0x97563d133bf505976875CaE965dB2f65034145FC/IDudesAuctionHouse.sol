// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Dudes Auction House

// LICENSE
// IDudesAuctionHouse.sol is a modified version of Nouns's INounsAuctionHouse.sol:
// https://github.com/nounsDAO/nouns-monorepo/blob/master/packages/nouns-contracts/contracts/interfaces/INounsAuctionHouse.sol
//
// INounsAuctionHouse.sol source code Copyright Nounders DAO licensed under the GPL-3.0 license.
// With modifications by the Dudes.

pragma solidity 0.8.15;

interface IDudesAuctionHouse {
  struct Auction {
    // ID for the DUDE (ERC721 token ID)
    uint256 dudeId;
    // The current highest bid amount
    // This will be the number of DUDE NFTs
    uint256 amount;
    // The time that the auction started
    uint256 startTime;
    // The time that the auction is scheduled to end
    uint256 endTime;
    // The address of the current highest bid
    address bidder;
    // Whether or not the auction has been settled
    bool settled;
    // array of dude token ids that were used to bid
    uint256[] biddedDudes;
  }

  event AuctionCreated(uint256 indexed dudeId, uint256 startTime, uint256 endTime);

  event AuctionBid(uint256 indexed dudeId, address sender, uint256 value, bool extended);

  event AuctionExtended(uint256 indexed dudeId, uint256 endTime);

  event AuctionSettled(uint256 indexed dudeId, address winner, uint256 amount);

  event AuctionTimeBufferUpdated(uint256 timeBuffer);

  event AuctionReservePriceUpdated(uint256 reservePrice);

  event AuctionMinBidIncrementPercentageUpdated(uint256 minBidIncrementPercentage);

  function getActiveAuction() external view returns (IDudesAuctionHouse.Auction memory);

  function getActiveAuctionBiddedDudes() external view returns (uint256[] memory);

  function settleAuction() external;

  function settleCurrentAndCreateNewAuction() external;

  function createBid(uint256 dudeId, uint256[] calldata dudesToUse) external;

  function setTimeBuffer(uint256 timeBuffer) external;

  function setReservePrice(uint256 reservePrice) external;

  function setMinBidIncrementPercentage(uint8 minBidIncrementPercentage) external;
}
