// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IAvnNftListingsV1 {

  enum State {
    Unlisted,
    Auction,
    Batch,
    Sale
  }

  struct Royalty {
    address recipient;
    uint32 partsPerMil;
  }

  struct Batch {
    uint64 supply;
    uint64 saleIndex;
    uint64 listingNumber;
  }

  struct Listing {
    uint256 price;
    uint256 endTime;
    uint256 saleFunds;
    address seller;
    uint64 avnOpId;
    State state;
  }

  struct Bid {
    address bidder;
    bytes32 avnPublicKey;
    uint256 amount;
  }

  event AvnTransferTo(uint256 indexed nftId, bytes32 indexed avnPublicKey, uint64 indexed avnOpId);
  event AvnMintTo(uint256 indexed batchId, uint64 indexed saleIndex, bytes32 indexed avnPublicKey, string uuid);
  event AvnEndBatchListing(uint256 indexed batchId);
  event AvnCancelNftListing(uint256 indexed nftId, uint64 indexed avnOpId);

  event LogStartAuction(uint256 indexed nftId, bytes32 indexed avnPublicKey, uint256 reservePrice, uint256 endTime);
  event LogBid(uint256 indexed nftId, bytes32 indexed avnPublicKey, uint256 amount);
  event LogAuctionComplete(uint256 indexed nftId, bytes32 indexed avnPublicKey, uint256 winningBid);
  event LogAuctionCancelled(uint256 indexed nftId);
  event LogStartBatchSale(uint256 indexed batchId, bytes32 indexed avnPublicKey, uint256 price, uint64 amountAvailable);
  event LogBatchSaleEnded(uint256 indexed batchId, uint64 amountRemaining);
  event LogBatchSaleCancelled(uint256 indexed batchId);
  event LogStartNftSale(uint256 indexed nftId, bytes32 indexed avnPublicKey, uint256 price);
  event LogSold(uint256 indexed nftId, bytes32 indexed avnPublicKey);
  event LogNftSaleCancelled(uint256 indexed nftId);
  event LogFundsDivertedOnFailure(address indexed intendedRecipient, address indexed authority, uint256 amount);

  function setAuthority(address authority, bool isAuthorised) external; // only Authority
  function getAuthorities() external view returns(address[] memory);
  function getRoyalties(uint256 batchIdOrNftId) external view returns(Royalty[] memory);
  function startAuction(uint256 nftId, bytes32 avnPublicKey, uint256 reservePrice, uint256 endTime, uint64 avnOpId,
      Royalty[] calldata royalties, bytes calldata proof) external;
  function bid(uint256 nftId, bytes32 avnPublicKey) external payable;
  function endAuction(uint256 nftId) external; // only Seller
  function cancelAuction(uint256 nftId) external; // either Seller or Authority
  function startBatchSale(uint256 batchId, bytes32 avnPublicKey, uint256 price, Batch calldata batchData,
      Royalty[] calldata royalties, bytes calldata proof) external;
  function buyFromBatch(uint256 batchId, bytes32 avnPublicKey) external payable;
  function endBatchSale(uint256 batchId) external; // only Seller
  function cancelBatchSale(uint256 batchId) external; // only Authority
  function startNftSale(uint256 nftId, bytes32 avnPublicKey, uint256 price, uint64 avnOpId, Royalty[] calldata royalties,
      bytes calldata proof) external;
  function buyNft(uint256 nftId, bytes32 avnPublicKey) external payable;
  function cancelNftSale(uint256 nftId) external; // either Seller or Authority
}