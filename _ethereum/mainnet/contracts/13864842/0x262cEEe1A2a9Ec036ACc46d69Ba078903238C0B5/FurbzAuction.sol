// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ERC721Holder.sol";
import "./Transactable.sol";
import "./IWETH.sol";
import "./IFurbz.sol";

contract FurbzAuctionHouse is Ownable, Transactable, Pausable, ERC721Holder, ReentrancyGuard {
  struct Auction {
    /** ID for the NFT */
    uint256 tokenID;
    /** The current highest bid amount */
    uint256 amount;
    /** The time that the auction started */
    uint256 startTime;
    /** The time that the auction is scheduled to end */
    uint256 endTime;
    /** The address of the current highest bid */
    address payable bidder;
    /** Whether or not the auction has been settled */
    bool settled;
  }
  /** The Furbz ERC721 contract */
  IFurbz public furbz;
  /** Receiver of auction funds */
  address public receiver;
  /** The address of the WETH contract */
  address public weth;
  /** The minimum amount of time left in an auction after a new bid is created */
  uint256 public timeBuffer;
  /** The minimum price accepted in an auction */
  uint256 public reservePrice;
  /** The minimum percentage difference between the last bid amount and the current bid */
  uint8 public minBidIncrementPercentage;
  /** The duration of a single auction */
  uint256 public duration;
  /** The active auction */
  Auction public auction;

  /** On auction create */
  event AuctionCreated(uint256 indexed furbId, uint256 startTime, uint256 endTime);
  /** On bid */
  event AuctionBid(uint256 indexed furbId, address sender, uint256 value, bool extended);
  /** On extend */
  event AuctionExtended(uint256 indexed furbId, uint256 endTime);
  /** On settled */
  event AuctionSettled(uint256 indexed furbId, address winner, uint256 amount);
  /** On buffer update */
  event AuctionTimeBufferUpdated(uint256 timeBuffer);
  /** On reserve price update */
  event AuctionReservePriceUpdated(uint256 reservePrice);
  /** On min bid update */
  event AuctionMinBidIncrementPercentageUpdated(uint256 minBidIncrementPercentage);

  constructor(
    IFurbz _furbz,
    address _weth,
    uint256 _timeBuffer,
    uint256 _reservePrice,
    uint8 _minBidIncrementPercentage,
    uint256 _duration
  ) {
    furbz = _furbz;
    weth = _weth;
    timeBuffer = _timeBuffer;
    reservePrice = _reservePrice;
    minBidIncrementPercentage = _minBidIncrementPercentage;
    duration = _duration;
  }

  /// @notice Settle the current auction, mint a new Furb, and put it up for auction.
  function settleCurrentAndCreateNewAuction() external nonReentrant whenNotPaused {
    _settleAuction();
    _createAuction();
  }

  /// @notice Settle the current auction.
  function settleAuction() external whenPaused nonReentrant {
    _settleAuction();
  }

  /// @notice Create a bid for a Furb, with a given amount.
  function createBid(uint256 furbId) external payable nonReentrant {
    Auction memory _auction = auction;

    require(_auction.tokenID == furbId, 'Furb not up for auction');
    require(block.timestamp < _auction.endTime, 'Auction expired');
    require(msg.value >= reservePrice, 'Must send at least reservePrice');
    require(
      msg.value >= _auction.amount + ((_auction.amount * minBidIncrementPercentage) / 100),
      'Must send more than last bid by minBidIncrementPercentage amount'
    );

    address payable lastBidder = _auction.bidder;

    if (lastBidder != address(0)) {
      _safeTransferETHWithFallback(lastBidder, _auction.amount);
    }
    auction.amount = msg.value;
    auction.bidder = payable(msg.sender);
    bool extended = _auction.endTime - block.timestamp < timeBuffer;

    if (extended) {
      auction.endTime = _auction.endTime = block.timestamp + timeBuffer;
    }
    emit AuctionBid(_auction.tokenID, msg.sender, msg.value, extended);

    if (extended) {
      emit AuctionExtended(_auction.tokenID, _auction.endTime);
    }
  }

  ///@notice Pause the auction house.
  function pause() external onlyOwner {
    _pause();
  }

  /// @notice Unpause the auction house.
  function unpause() external onlyOwner {
    _unpause();

    if (auction.startTime == 0 || auction.settled) {
        _createAuction();
    }
  }

  /// @notice Set the auction time buffer.
  function setTimeBuffer(uint256 _timeBuffer) external onlyOwner {
    timeBuffer = _timeBuffer;
    emit AuctionTimeBufferUpdated(_timeBuffer);
  }

  /// @notice Set the auction reserve price.
  function setReservePrice(uint256 _reservePrice) external onlyOwner {
    reservePrice = _reservePrice;
    emit AuctionReservePriceUpdated(_reservePrice);
  }

  /// @notice Set the auction minimum bid increment percentage.
  function setMinBidIncrementPercentage(uint8 _minBidIncrementPercentage) external onlyOwner {
    minBidIncrementPercentage = _minBidIncrementPercentage;
    emit AuctionMinBidIncrementPercentageUpdated(_minBidIncrementPercentage);
  }

  /// @notice Set the receiver of funds.
  function setReceiver(address val) external onlyOwner {
    receiver = val;
  }

  /// @notice Sets the furbz ERC721 contract
  /// @param val Contract addr
  function setFurbz(IFurbz val) external onlyOwner {
    furbz = val;
  }

  /// @notice Create an auction.
  function _createAuction() internal {
    try furbz.mint() returns (uint256 furbId) {
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + duration;
        auction = Auction({
            tokenID: furbId,
            amount: 0,
            startTime: startTime,
            endTime: endTime,
            bidder: payable(0),
            settled: false
        });

        emit AuctionCreated(furbId, startTime, endTime);
      } catch Error(string memory) {
        _pause();
      }
  }

  /// @notice Settle an auction, finalizing the bid.
  function _settleAuction() internal {
    Auction memory _auction = auction;
    require(_auction.startTime != 0, "Auction hasn't begun");
    require(!_auction.settled, 'Auction has already been settled');
    require(block.timestamp >= _auction.endTime, "Auction hasn't completed");
    auction.settled = true;

    if (_auction.bidder == address(0)) {
      furbz.burn(_auction.tokenID);
    } else {
      furbz.transferFrom(address(this), _auction.bidder, _auction.tokenID);
    }
    if (_transactable) {
      _safeTransferETHWithFallback(receiver, address(this).balance);
    }

    emit AuctionSettled(_auction.tokenID, _auction.bidder, _auction.amount);
  }

  /// @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
  function _safeTransferETHWithFallback(address to, uint256 amount) internal {
    if (!_safeTransferETH(to, amount)) {
      IWETH(weth).deposit{ value: amount }();
      IERC20(weth).transfer(to, amount);
    }
  }

  /// @notice Transfer ETH and return the success status.
  function _safeTransferETH(address to, uint256 value) internal returns (bool) {
    (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
    return success;
  }
}