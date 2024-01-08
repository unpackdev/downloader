// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IAvnNftRoyaltyStorage.sol";

interface IAvnNftListingsV1 {

  enum State {
    Unlisted,
    Auction,
    Batch,
    Sale
  }

  struct Listing {
    uint256 price;
    uint256 endTime;
    uint256 saleFunds;
    address seller;
    uint64 avnOpId;
    uint64 supply;
    uint64 saleIndex;
    State state;
  }

  struct Bid {
    address bidder;
    bytes32 avnPublicKey;
    uint256 amount;
  }

  event AvnTransferTo(uint256 indexed nftId, bytes32 indexed avnPublicKey, uint64 indexed avnOpId);
  event AvnMintTo(uint256 indexed nftId, bytes32 indexed avnPublicKey);
  event AvnCancelBatchListing(uint256 indexed batchId);
  event AvnCancelNftListing(uint256 indexed nftId, uint64 indexed avnOpId);

  event LogStartAuction(uint256 indexed nftId, address indexed seller, uint256 reservePrice, uint256 endTime);
  event LogBid(uint256 indexed nftId, address indexed bidder, bytes32 indexed avnPublicKey, uint256 amount);
  event LogAuctionComplete(uint256 indexed nftId, bytes32 indexed avnPublicKey, address indexed winner, uint256 winningBid);
  event LogAuctionCancelled(uint256 indexed nftId);
  event LogStartBatchSale(uint256 indexed batchId, address indexed seller, uint256 price, uint64 supply, uint256 endTime);
  event LogSold(uint256 indexed nftId, bytes32 indexed avnPublicKey, address indexed buyer);
  event LogBatchSaleComplete(uint256 indexed batchId, uint64 amountSold);
  event LogBatchSaleCancelled(uint256 indexed batchId);
  event LogStartNftSale(uint256 indexed nftId, address indexed seller, uint256 price);
  event LogNftSaleCancelled(uint256 indexed nftId);

  function setAuthority(address authority, bool isAuthorised) external; // onlyOwner
  function startAuction(uint256 nftId, uint256 reservePrice, uint256 endTime, uint64 avnOpId,
      IAvnNftRoyaltyStorage.Royalty[] calldata royalties, bytes calldata proof) external;
  function bid(uint256 nftId, bytes32 avnPublicKey) external payable;
  function endAuction(uint256 nftId) external; // onlySeller
  function cancelAuction(uint256 nftId) external; // either Seller, Owner, or Authority
  function startBatchSale(uint256 batchId, uint256 price, uint256 endTime, uint64 supply,
      IAvnNftRoyaltyStorage.Royalty[] calldata royalties, bytes calldata proof) external;
  function buyFromBatch(uint256 batchId, bytes32 avnPublicKey) external payable;
  function endBatchSale(uint256 batchId) external; // onlySeller
  function startNftSale(uint256 nftId, uint256 price, uint64 avnOpId, bytes calldata proof) external;
  function buyNft(uint256 nftId, bytes32 avnPublicKey) external payable;
  function cancelNftSale(uint256 nftId) external; // either Seller, Owner, or Authority
}