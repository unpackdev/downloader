// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "./Ownable.sol";
import "./Pausable.sol";
import "./Counters.sol";

contract Auction is Ownable, Pausable {
  using Counters for Counters.Counter;

  uint256 public constant hoursInSeconds = 60 * 60;
  uint256 public constant auctionEndThresholdHrs = 1;

  uint256 public immutable minimumUnitPrice;
  uint256 public immutable minimumBidIncrement;
  uint256 public immutable unitPriceStepSize;
  uint256 public immutable minimumQuantity;
  uint256 public immutable maximumQuantity;
  uint256 public immutable itemsPerDay;
  uint256 public immutable auctionLengthHrs;
  uint256 public immutable auctionEnd;

  address payable public immutable beneficiaryAddress;

  Counters.Counter private _bidPlacedCounter;

  event AuctionStarted();
  event AuctionEnded();
  event BidPlaced(
    address indexed bidder,
    uint256 bidIndex,
    uint256 unitPrice,
    uint256 quantity
  );
  event BidderRefunded(address indexed bidder, uint256 refundAmount);

  struct Bid {
    uint128 unitPrice;
    uint128 quantity;
  }

  struct AuctionStatus {
    bool started;
    bool ended;
  }

  // current auction status
  AuctionStatus public auctionStatus;
  // bidder address => current bid
  mapping(address => Bid) private _bids;

  // Beneficiary address cannot be changed after deployment.
  constructor(
    address payable _beneficiaryAddress,
    uint256 _minimumUnitPrice,
    uint256 _minimumBidIncrement,
    uint256 _unitPriceStepSize,
    uint256 _minimumQuantity,
    uint256 _maximumQuantity,
    uint256 _itemsPerDay,
    uint256 _auctionLengthHrs,
    uint256 _auctionEnd
  ) {
    beneficiaryAddress = _beneficiaryAddress;
    minimumUnitPrice = _minimumUnitPrice;
    minimumBidIncrement = _minimumBidIncrement;
    unitPriceStepSize = _unitPriceStepSize;
    minimumQuantity = _minimumQuantity;
    maximumQuantity = _maximumQuantity;
    itemsPerDay = _itemsPerDay;
    auctionLengthHrs = _auctionLengthHrs;
    require(
      _auctionEnd >= (block.timestamp + (auctionLengthHrs * hoursInSeconds)),
      "Auction end must be at least auction duration from now"
    );
    auctionEnd = _auctionEnd;
    pause();
  }

  modifier whenAuctionActive() {
    require(!auctionStatus.ended, "Auction has already ended.");
    require(auctionStatus.started, "Auction hasn't started yet.");
    _;
  }

  modifier whenPreAuction() {
    require(!auctionStatus.ended, "Auction has already ended.");
    require(!auctionStatus.started, "Auction has already started.");
    _;
  }

  modifier whenAuctionEnded() {
    require(auctionStatus.ended, "Auction hasn't ended yet.");
    require(auctionStatus.started, "Auction hasn't started yet.");
    _;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function bidsPlacedCount() external view returns (uint256) {
    return _bidPlacedCounter.current();
  }

  function startAuction() external onlyOwner whenPreAuction {
    auctionStatus.started = true;
    if (paused()) {
      unpause();
    }
    emit AuctionStarted();
  }

  function endAuction() external onlyOwner whenAuctionActive {
    require(block.timestamp >= auctionEnd, "Auction end time not reached");
    auctionStatus.ended = true;
    if (!paused()) {
      pause();
    }
    emit AuctionEnded();
  }

  function endAuctionFromBid() internal whenAuctionActive {
    auctionStatus.ended = true;
    if (!paused()) {
      _pause();
    }
    emit AuctionEnded();
  }

  function getBid(address bidder) external view returns (Bid memory) {
    return _bids[bidder];
  }

  // Refunds losing bidders from the contract's balance.
  function refundBidders(
    address payable[] calldata bidders_,
    uint128[] calldata quantities_
  ) external onlyOwner whenPaused whenAuctionEnded {
    require(
      bidders_.length == quantities_.length,
      "bidders length doesn't match quantities length"
    );

    for (uint256 i = 0; i < bidders_.length; i++) {
      require(quantities_[i] > 0, "Quantity is 0");
      address payable bidder = bidders_[i];
      uint128 refundAmount = _bids[bidder].unitPrice * quantities_[i];

      // Since we deduct from bid.quantity when we issue a refund, this gives us the up-to-date maximum that can still be refunded.
      uint128 refundMaximum = _bids[bidder].unitPrice * _bids[bidder].quantity;

      require(
        refundAmount <= refundMaximum,
        "Refund amount is greater than balance"
      );

      // Skip bidders who aren't entitled to a refund.
      if (refundAmount == 0 || refundMaximum == 0) {
        continue;
      }

      _bids[bidder].quantity -= quantities_[i];
      (bool success, ) = bidder.call{value: refundAmount}("");
      require(success, "Transfer failed.");
      emit BidderRefunded(bidder, refundAmount);
    }
  }

  function withdrawContractBalance() external onlyOwner {
    (bool success, ) = beneficiaryAddress.call{value: address(this).balance}(
      ""
    );
    require(success, "Transfer failed.");
  }

  // When a bidder places a bid or updates their existing bid, they will use this function.
  // - total value can never be lowered
  // - unit price can never be lowered
  // - quantity can be raised or lowered, but only if unit price is raised to meet or exceed previous total price
  function placeBid(uint256 quantity, uint256 unitPrice)
    external
    payable
    whenNotPaused
    whenAuctionActive
  {
    // If the bidder is increasing their bid, the amount being added must be greater than or equal to the minimum bid increment.
    if (msg.value > 0 && msg.value < minimumBidIncrement) {
      revert("Bid lower than minimum bid increment.");
    }

    // Cache initial bid values.
    uint256 initialUnitPrice = _bids[msg.sender].unitPrice;
    uint256 initialQuantity = _bids[msg.sender].quantity;
    uint256 initialTotalValue = initialUnitPrice * initialQuantity;

    // Cache final bid values.
    uint256 finalUnitPrice = unitPrice;
    uint256 finalQuantity = quantity;
    uint256 finalTotalValue = initialTotalValue + msg.value;

    // Don't allow bids with a unit price scale smaller than unitPriceStepSize.
    // For example, allow 1.01 or 111.01 but don't allow 1.011.
    require(
      finalUnitPrice % unitPriceStepSize == 0,
      "Unit price step too small."
    );

    // Reject bids that don't have a quantity within the valid range.
    require(finalQuantity >= minimumQuantity, "Quantity too low.");
    require(finalQuantity <= maximumQuantity, "Quantity too high.");

    // Total value can never be lowered.
    require(
      finalTotalValue >= initialTotalValue,
      "Total value can't be lowered."
    );

    // Unit price can never be lowered.
    // Quantity can be raised or lowered, but it can only be lowered if the unit price is raised to meet or exceed the initial total value. Ensuring the the unit price is never lowered takes care of this.
    require(finalUnitPrice >= initialUnitPrice, "Unit price can't be lowered.");

    // Ensure the new totalValue equals quantity * the unit price that was given in this txn exactly. This is important to prevent rounding errors later when returning ether.
    require(
      finalQuantity * finalUnitPrice == finalTotalValue,
      "Quantity * Unit Price != Total Value"
    );

    // Unit price must be greater than or equal to the minimumUnitPrice.
    require(finalUnitPrice >= minimumUnitPrice, "Bid unit price too low.");

    // Something must be changing from the initial bid for this new bid to be valid.
    if (
      initialUnitPrice == finalUnitPrice && initialQuantity == finalQuantity
    ) {
      revert("This bid doesn't change anything.");
    }

    // Update the bidder's bid.
    _bids[msg.sender].unitPrice = uint128(finalUnitPrice);
    _bids[msg.sender].quantity = uint128(finalQuantity);

    emit BidPlaced(
      msg.sender,
      _bidPlacedCounter.current(),
      finalUnitPrice,
      finalQuantity
    );
    // Increment after emitting the BidPlaced event because counter is 0-indexed.
    _bidPlacedCounter.increment();

    // After the bid has been placed, check to see whether the auction is ended
    _checkAuctionEnd();
  }

  // Handles receiving ether to the contract.
  // Reject all direct payments to the contract except from beneficiary and owner.
  // Bids must be placed using the placeBid function.
  receive() external payable {
    require(msg.value > 0, "No ether was sent.");
    require(
      msg.sender == beneficiaryAddress || msg.sender == owner(),
      "Only owner or beneficiary can fund contract."
    );
  }

  function _checkAuctionEnd() internal {
    // (1) If we are at or past the end time it's the end of the action:
    if (block.timestamp >= auctionEnd) {
      endAuctionFromBid();
    } else {
      // (2) Still going? See if we are in the threshold:
      uint256 auctionEndThreshold = auctionEnd -
        (auctionEndThresholdHrs * hoursInSeconds);
      if (block.timestamp >= auctionEndThreshold) {
        // End logic is simple, we do a modulo on the random number using the number of
        // seconds until the end of the action, and check if the remainder is = 7
        // as we approach the end of the auction the odds of such a small remainder increase
        // (while being possible at all times in the threshold)
        if (_getRandomNumber() % (auctionEnd - block.timestamp) == 7) {
          endAuctionFromBid();
        }
      }
    }
  }

  function _getRandomNumber() internal view returns (uint256) {
    return
      uint256(
        keccak256(
          abi.encodePacked(
            _bidPlacedCounter.current(),
            blockhash(block.number - 1)
          )
        )
      );
  }
}
