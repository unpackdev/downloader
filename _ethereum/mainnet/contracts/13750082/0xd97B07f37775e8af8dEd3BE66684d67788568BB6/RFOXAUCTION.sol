//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./OwnerPausable.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";

contract RFOXAUCTION is OwnerPausable, IERC721Receiver {
  using SafeMath for uint256;

  enum AuctionStatus { Normal, Ended, Canceled }
  struct AuctionInfo {
    address seller;
    address nft;
    uint itemId;
    uint price;
    address bidder;
    uint createdAt;
    uint updatedAt;
    uint start;
    uint end;
    AuctionStatus status;
  }

  struct BidInfo {
    uint auctionId;
    uint itemId;
    uint price;
    address bidder;
    uint bidAt;
  }

  AuctionInfo[] public auctions;
  BidInfo[] public bids;
  uint256 public bidPricePercent;

  mapping(uint256 => uint256[]) public bidsOfAuction;
  mapping(address => uint256[]) public bidsOfUser;

  mapping(address => uint256) public bidCount;
  mapping(address => uint256) public wonCount;

  // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`

  uint private constant MIN_BID_PRICE_PERCENT = 101;
  uint private constant MAX_BID_PRICE_PERCNET = 120;

  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

  event CreateAuction(address indexed sender, uint itemId, uint start, uint end);
  event Bid(address indexed sender, uint auctionId, uint price, uint bidAt);
  event CancelAuction(address indexed sender, uint auctionId);
  event EndAuction(address indexed sender, uint auctionId);
  event SetBidPricePercent(address indexed sender, uint _bidPricePercent);

  constructor (uint256 _bidPricePercent) {
    require(_bidPricePercent >= MIN_BID_PRICE_PERCENT &&
            _bidPricePercent <= MAX_BID_PRICE_PERCNET, "Auction: Invalid Bid Price Percent");

    bidPricePercent = _bidPricePercent;
  }

  modifier validId(uint _auctionId) {
    require(_auctionId < auctions.length, "Auction: Invalid Auction Id");
    _;
  }
  
  modifier validSeller(uint _auctionId) {
    AuctionInfo storage auction = auctions[_auctionId];
    require(auction.seller == _msgSender(), "Auction: Invalid Permission");
    _;
  }

  modifier validWinner(uint _auctionId) {
    AuctionInfo storage auction = auctions[_auctionId];
    require(auction.bidder == _msgSender(), "Auction: Invalid Permission");
    _;
  }

  /**
   * Create a new auction
   *
   * @param _nft address of nft
   * @param _itemId token id of nft
   * @param _price start price
   * @param _start start date
   * @param _end end date
  */
  function createAuction(address _nft, uint _itemId, uint _price,  uint _start, uint _end) external onlyOwner whenNotPaused {
    require(_start < _end, "Auction: Period is not valid");
    IERC721(_nft).safeTransferFrom(_msgSender(), address(this), _itemId);
    AuctionInfo memory newAuction = AuctionInfo(
                                      _msgSender(),
                                      _nft,
                                      _itemId,
                                      _price,
                                      address(0),
                                      block.timestamp,
                                      block.timestamp,
                                      _start,
                                      _end,
                                      AuctionStatus.Normal
                                    );
    auctions.push(newAuction);
    emit CreateAuction(_msgSender(), _itemId, _start, _end);
  }

  /**
   * Bid to an auction
   *
   * @param _auctionId auction id to bid
  */
  function bid(uint _auctionId) external validId(_auctionId) whenNotPaused payable {
    AuctionInfo storage auction = auctions[_auctionId];
    require(_msgSender() != auction.seller, "Auction: Invalid Bidder");
    require(_msgSender() != auction.bidder, "Auction: Invalid Bidder");
    require(block.timestamp >= auction.start, "Auction: Auction is not started");
    require(block.timestamp <= auction.end, "Auction: Auction is Over");
    require(msg.value > auction.price.mul(bidPricePercent).div(100), "Auction: Price is low");
    require(auction.status == AuctionStatus.Normal, "Auction: Bid is not allowed");

    // Require bidder is not highest bidder on another auction
    // require(bidCount[_msgSender()] == 0, "Auction: Bidder can only win 1 shop at a time");

    if (auction.bidder != address(0)) {
      bidCount[auction.bidder] = bidCount[auction.bidder].sub(1);
      (bool success, ) = auction.bidder.call{ value: auction.price}("");
      require(success, 'Auction: unable to send value, recipient may have reverted');
    }
    
    bidCount[_msgSender()] = bidCount[_msgSender()].add(1);

    auction.bidder = _msgSender();
    auction.price = msg.value;
    auction.updatedAt = block.timestamp;

    BidInfo memory newBid = BidInfo(_auctionId, auction.itemId, msg.value, _msgSender(), block.timestamp);
    bids.push(newBid);

    bidsOfAuction[_auctionId].push(bids.length - 1);
    bidsOfUser[_msgSender()].push(bids.length - 1);

    emit Bid(_msgSender(), _auctionId, msg.value, block.timestamp);
  }

  /**
   * Cancel an auction
   *
   * @param _auctionId auction id to cancel
  */
  function cancelAuction(uint _auctionId) external validId(_auctionId) validSeller(_auctionId) whenNotPaused {
    AuctionInfo storage auction = auctions[_auctionId];
    require(auction.start > block.timestamp, "Auction: Not Cancelable");
    require(bidsOfAuction[_auctionId].length == 0, "Auction: There are bids already");
    auction.status = AuctionStatus.Canceled;

    IERC721(auction.nft).safeTransferFrom(address(this), _msgSender(), auction.itemId);
    emit CancelAuction(_msgSender(), _auctionId);
  }

  /**
   * Set percent of price to bid higher than current price
   *
   * @param _bidPricePercent percent
  */
  function setBidPricePercent(uint _bidPricePercent) external onlyOwner {
    require(_bidPricePercent >= MIN_BID_PRICE_PERCENT && _bidPricePercent <= MAX_BID_PRICE_PERCNET, "Invalid Bid Price Percent");
    bidPricePercent = _bidPricePercent;
    emit SetBidPricePercent(_msgSender(), _bidPricePercent);
  }

  /**
   * Return total number of auctions
   *
   * @return number of auctions
  */
  function getAuctionCount() external view returns (uint256) {
    return auctions.length;
  }

  /**
   * Return total number of auctions
   *
   * @return number of auctions
  */
  function getTotalBidCount() external view returns (uint256) {
    return bids.length;
  }

  /**
   * End an auction
   *
   * @param _auctionId auction id to end
  */
  function endAuction(uint _auctionId) external validId(_auctionId) validSeller(_auctionId) {
    _finalizeAuction(_auctionId);
  }

  /**
   * Claim an auction
   *
   * @param _auctionId auction id to end
  */
  function claimAuction(uint _auctionId) external validId(_auctionId) validWinner(_auctionId) {
    _finalizeAuction(_auctionId);
  }

  function _finalizeAuction(uint _auctionId) private {
    AuctionInfo storage auction = auctions[_auctionId];
    require(auction.end < block.timestamp, "Auction: Not ended yet");

    require(auction.status == AuctionStatus.Normal);
    auction.status = AuctionStatus.Ended;

    if(auction.bidder != address(0)) {
      (bool success, ) = auction.seller.call{ value: auction.price}("");
      require(success, 'Auction: unable to send value, recipient may have reverted');
      IERC721(auction.nft).safeTransferFrom(address(this), auction.bidder, auction.itemId);
    }

    wonCount[auction.bidder] = wonCount[auction.bidder].add(1);
    emit EndAuction(_msgSender(), _auctionId);
  }

  /**
   * Get bids of an auction
   *
   * @param _auctionId auction id
   *
   * @return bids
  */
  function getAuctionActivities(uint256 _auctionId) external view returns (uint256[] memory) {
    return bidsOfAuction[_auctionId];
  }
  
  /**
   * Get bids of user
   *
   * @param account address of user
   *
   * @return bids
  */
  function getUserBidding(address account) external view returns (uint256[] memory) {
    return bidsOfUser[account];
  }

  function onERC721Received(address, address, uint256, bytes calldata) external override pure returns (bytes4) {
    return _ERC721_RECEIVED;
  }
}
