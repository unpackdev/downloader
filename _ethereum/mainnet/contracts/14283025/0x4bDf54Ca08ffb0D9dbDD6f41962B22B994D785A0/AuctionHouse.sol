// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Counters.sol";
import "./IERC20.sol";
import "./ABDKMath64x64.sol";

contract AuctionHouse is Ownable {
  using ABDKMath64x64 for int128;
  using Counters for Counters.Counter;
  Counters.Counter private _nextAuctionId;

  struct Auction {
    bool exists;
    uint96 startingPrice;
    uint48 startingTime;
    uint16 quantity;
    uint16 depreciationFactor; // price depreciation per interval, in basis points
    uint32 depreciationInterval;
    uint16 bids;
  }

  event AuctionCreated(uint256 indexed auctionId);
  event AuctionUpdated(uint256 indexed auctionId);

  event SuccessfulBid(
    uint256 indexed auctionId,
    address indexed sender,
    uint96 price
  );

  address public rainbows; // rainbows contract address
  address public payee; // send auction proceeds to this address

  mapping(uint256 => Auction) public auctions;

  modifier validAuction(uint256 auctionId) {
    require(auctions[auctionId].exists, 'Invalid auction id');
    _;
  }

  constructor(address rainbowsAddress) {
    rainbows = rainbowsAddress;
    payee = msg.sender;
  }

  function createAuction(
    uint256 startingPrice,
    uint256 startingTime,
    uint256 quantity,
    uint256 depreciationFactor,
    uint256 depreciationInterval
  ) external onlyOwner returns (uint256) {
    Auction memory auction = Auction(
      true,
      uint96(startingPrice),
      uint48(startingTime),
      uint16(quantity),
      uint16(depreciationFactor),
      uint32(depreciationInterval),
      uint16(0)
    );

    uint256 auctionId = _nextAuctionId.current();
    _nextAuctionId.increment();
    auctions[auctionId] = auction;

    emit AuctionCreated(auctionId);
    return auctionId;
  }

  function updateAuction(
    uint256 auctionId,
    uint256 startingPrice,
    uint256 startingTime,
    uint256 quantity,
    uint256 depreciationFactor,
    uint256 depreciationInterval
  ) external onlyOwner validAuction(auctionId) {
    Auction memory auction = auctions[auctionId];

    require(quantity >= auction.bids, 'Quantity too small');

    auction.startingPrice = uint96(startingPrice);
    auction.startingTime = uint48(startingTime);
    auction.quantity = uint16(quantity);
    auction.depreciationFactor = uint16(depreciationFactor);
    auction.depreciationInterval = uint32(depreciationInterval);

    auctions[auctionId] = auction;
    emit AuctionUpdated(auctionId);
  }

  function currentPrice(uint256 auctionId)
    public
    view
    validAuction(auctionId)
    returns (uint256)
  {
    return priceAtTime(auctionId, block.timestamp);
  }

  function priceAtTime(uint256 auctionId, uint256 timestamp)
    public
    view
    validAuction(auctionId)
    returns (uint256)
  {
    Auction storage auction = auctions[auctionId];

    if (timestamp < auction.startingTime || auction.depreciationFactor == 0) {
      return auction.startingPrice;
    }

    uint256 intervalCount = (timestamp - auction.startingTime) /
      auction.depreciationInterval;

    return
      calculatePrice(
        auction.startingPrice,
        auction.depreciationFactor,
        intervalCount
      );
  }

  function calculatePrice(
    uint256 startingPrice,
    uint256 depreciationFactor,
    uint256 depreciationCount
  ) public pure returns (uint256) {
    uint256 depreciation = ABDKMath64x64
      .fromInt(1)
      .sub(ABDKMath64x64.divu(depreciationFactor, 10_000))
      .pow(depreciationCount)
      .mulu(1 ether);

    return (startingPrice * depreciation) / (1 ether);
  }

  function nextPriceChange(uint256 auctionId, uint256 timestamp)
    external
    view
    validAuction(auctionId)
    returns (uint256)
  {
    Auction storage auction = auctions[auctionId];

    uint256 intervalCount = (timestamp - auction.startingTime) /
      auction.depreciationInterval +
      1;

    return auction.startingTime + auction.depreciationInterval * intervalCount;
  }

  function submitBid(uint256 auctionId) public validAuction(auctionId) {
    require(isActive(auctionId), 'Auction is not active');

    uint256 price = currentPrice(auctionId);
    IERC20 Rainbows = IERC20(rainbows);
    require(Rainbows.balanceOf(msg.sender) >= price, 'Insufficient rainbows');
    Rainbows.transferFrom(msg.sender, payee, price);

    Auction storage auction = auctions[auctionId];
    auction.bids++;

    emit SuccessfulBid(auctionId, msg.sender, uint96(price));
  }

  function isActive(uint256 auctionId)
    public
    view
    validAuction(auctionId)
    returns (bool)
  {
    Auction storage auction = auctions[auctionId];

    return
      block.timestamp >= auction.startingTime &&
      auction.bids < auction.quantity;
  }

  function setTokenAddress(address newAddress) external onlyOwner {
    rainbows = newAddress;
  }

  function setPayeeAddress(address newAddress) external onlyOwner {
    payee = newAddress;
  }
}