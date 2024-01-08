// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Ownable.sol";
import "./Pausable.sol";
import "./Counters.sol";

contract Auction is Ownable, Pausable {
  using Counters for Counters.Counter;

  uint256 public immutable minimumUnitPrice;
  uint256 public immutable minimumBidIncrement;
  uint256 public immutable unitPriceStepSize;
  uint256 public immutable minimumQuantity;
  uint256 public immutable maximumQuantity;
  uint256 public immutable numberOfAuctions;
  uint256 public immutable itemsPerDay;
  address payable public immutable beneficiaryAddress;

  Counters.Counter private _auctionIDCounter;
  Counters.Counter private _bidPlacedCounter;

  bool private _allowWithdrawals;

  event AuctionStarted(uint256 auctionID);
  event AuctionEnded(uint256 auctionID);
  event BidPlaced(uint256 indexed auctionID, address indexed bidder, uint256 bidIndex, uint256 unitPrice, uint256 quantity);
  event WinnerSelected(uint256 indexed auctionID, address indexed bidder, uint256 unitPrice, uint256 quantity);
  event BidderRefunded(address indexed bidder, uint256 refundAmount);

  struct Bid {
    uint256 unitPrice;
    uint256 quantity;
  }

  struct AuctionStatus {
    bool started;
    bool ended;
  }

  // auctionID => auction status tracker
  mapping (uint256 => AuctionStatus) private _auctionStatus;
  // bidder address => current bid
  mapping (address => Bid) private _bids;
  // auctionID => remainingItemsPerAuction
  mapping (uint256 => uint256) private _remainingItemsPerAuction;

  // Ownership is immediately transferred to contractOwner.
  // Beneficiary address cannot be changed after deployment.
  constructor(
    address _contractOwner,
    address payable _beneficiaryAddress,
    uint256 _minimumUnitPrice,
    uint256 _minimumBidIncrement,
    uint256 _unitPriceStepSize,
    uint256 _minimumQuantity,
    uint256 _maximumQuantity,
    uint256 _numberOfAuctions,
    uint256 _itemsPerDay
  ) {
    beneficiaryAddress = _beneficiaryAddress;
    transferOwnership(_contractOwner);
    minimumUnitPrice = _minimumUnitPrice;
    minimumBidIncrement = _minimumBidIncrement;
    unitPriceStepSize = _unitPriceStepSize;
    minimumQuantity = _minimumQuantity;
    maximumQuantity = _maximumQuantity;
    numberOfAuctions = _numberOfAuctions;
    itemsPerDay = _itemsPerDay;
    // Set up the _remainingItemsPerAuction tracker.
    for(uint256 i = 0; i < _numberOfAuctions; i++) {
      _remainingItemsPerAuction[i] = _itemsPerDay;
    }
    pause();
  }

  modifier whenAuctionActive() {
    require(!currentAuctionStatus().ended, "Auction has already ended.");
    require(currentAuctionStatus().started, "Auction hasn't started yet.");
    _;
  }

  modifier whenPreAuction() {
    require(!currentAuctionStatus().ended, "Auction has already ended.");
    require(!currentAuctionStatus().started, "Auction has already started.");
    _;
  }

  modifier whenAuctionEnded() {
    require(currentAuctionStatus().ended, "Auction hasn't ended yet.");
    require(currentAuctionStatus().started, "Auction hasn't started yet.");
    _;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function setAllowWithdrawals(bool allowWithdrawals_) public onlyOwner {
    _allowWithdrawals = allowWithdrawals_;
  }

  function getAllowWithdrawals() public view returns (bool) {
    return _allowWithdrawals;
  }

  function auctionStatus(uint256 _auctionID) public view returns (AuctionStatus memory) {
    return _auctionStatus[_auctionID];
  }

  function currentAuctionStatus() public view returns (AuctionStatus memory) {
    return _auctionStatus[getCurrentAuctionID()];
  }

  // Returns the balance currently held in this contract.
  function contractBalance() external view returns (uint256) {
    return address(this).balance;
  }

  function bidsPlacedCount() external view returns (uint256) {
    return _bidPlacedCounter.current();
  }

  function getCurrentAuctionID() public view returns (uint) {
    return _auctionIDCounter.current();
  }

  function incrementAuctionID() public onlyOwner whenPaused whenAuctionEnded {
    _auctionIDCounter.increment();
    require(_auctionIDCounter.current() < numberOfAuctions, "Max number of auctions reached.");
  }

  // this function should only ever be used if something goes wrong, so it doesn't have the whenAuctionEnded modifier
  function decrementAuctionID() public onlyOwner whenPaused {
    _auctionIDCounter.decrement();
  }

  function startAuction() external onlyOwner whenPreAuction {
    uint256 currentAuctionID = getCurrentAuctionID();
    _auctionStatus[currentAuctionID].started = true;
    if (paused()) {
      unpause();
    }
    emit AuctionStarted(currentAuctionID);
  }

  function endAuction() external onlyOwner whenAuctionActive {
    uint256 currentAuctionID = getCurrentAuctionID();
    _auctionStatus[currentAuctionID].ended = true;
    if (!paused()) {
      pause();
    }
    emit AuctionEnded(currentAuctionID);
  }

  function getBid(address bidder) external view returns (Bid memory) {
    return _bids[bidder];
  }

  function getRemainingItemsForAuction(uint256 auctionID) external view returns (uint256) {
    require(auctionID < numberOfAuctions, "Invalid auctionID.");
    return _remainingItemsPerAuction[auctionID];
  }

  // Requires a sorted list of winners. You can submit the winners in any batch size you want, but order matters.
  function selectWinners(address[] calldata bidders) external onlyOwner whenPaused whenAuctionEnded {
    uint256 auctionID = getCurrentAuctionID();
    // Iterate over each winning address until we reach the end of the winners list or we deplete _remainingItemsPerAuction for this auctionID.
    for(uint256 i = 0; i < bidders.length; i++) {
      address bidder = bidders[i];
      uint256 bidUnitPrice = _bids[bidder].unitPrice;
      uint256 bidQuantity = _bids[bidder].quantity;

      // Skip bidders whose bid quantity or unit price is already 0.
      if (bidUnitPrice == 0 || bidQuantity == 0) {
        continue;
      }

      if (_remainingItemsPerAuction[auctionID] == bidQuantity) {
        // STOP: _remainingItemsPerAuction has been depleted, and the quantity for this bid made us hit 0 exactly.
        _bids[bidder] = Bid(0,0);
        emit WinnerSelected(auctionID, bidder, bidUnitPrice, bidQuantity);
        _remainingItemsPerAuction[auctionID] = 0;
        break;
      } else if (_remainingItemsPerAuction[auctionID] < bidQuantity) {
        // STOP: _remainingItemsPerAuction has been depleted, and the quantity for this bid made us go negative (quantity too high to give the bidder all they asked for)
        emit WinnerSelected(auctionID, bidder, bidUnitPrice, _remainingItemsPerAuction[auctionID]);
        // Don't set unitPrice to 0 here as there is still at least 1 quantity remaining.
        // Must set _remainingItemsPerAuction to 0 AFTER this.
        _bids[bidder].quantity -= _remainingItemsPerAuction[auctionID];
        _remainingItemsPerAuction[auctionID] = 0;
        break;
      } else {
        // CONTINUE: _remainingItemsPerAuction hasn't been depleted yet...
        _bids[bidder] = Bid(0,0);
        emit WinnerSelected(auctionID, bidder, bidUnitPrice, bidQuantity);
        _remainingItemsPerAuction[auctionID] -= bidQuantity;
      }
    }
  }

  // Refunds losing bidders from the contract's balance.
  function refundBidders(address payable[] calldata bidders) external onlyOwner whenPaused whenAuctionEnded {
    uint256 totalRefundAmount = 0;
    for(uint256 i = 0; i < bidders.length; i++) {
      address payable bidder = bidders[i];
      uint256 refundAmount = _bids[bidder].unitPrice * _bids[bidder].quantity;

      // Skip bidders who aren't entitled to a refund.
      if (refundAmount == 0) {
        continue;
      }

      _bids[bidder] = Bid(0,0);
      (bool success, ) = bidder.call{ value: refundAmount }("");
      require(success, "Transfer failed.");
      totalRefundAmount += refundAmount;
      emit BidderRefunded(bidder, refundAmount);
    }
  }

  function withdrawContractBalance() external onlyOwner {
    (bool success, ) = beneficiaryAddress.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  // Note: this function allows claiming refunds even before the winners are selected. It's up to the owner to only allow withdrawals when appropriate.
  // It's also the responsbility of the owner to keep enough ether in the contract for refunds.
  function claimRefund() external whenPaused whenAuctionEnded {
    // This must be the final auction.
    require(getCurrentAuctionID() == (numberOfAuctions - 1), "Withdrawals allowed after final auction has ended.");
    // Withdrawals must not be paused.
    require(_allowWithdrawals, "Withdrawals are not allowed right now.");
    uint256 refundAmount = _bids[msg.sender].unitPrice * _bids[msg.sender].quantity;
    require(refundAmount > 0, "Refund amount is 0.");
    _bids[msg.sender] = Bid(0,0);
    (bool success, ) = msg.sender.call{ value: refundAmount }("");
    require(success, "Transfer failed.");
    emit BidderRefunded(msg.sender, refundAmount);
  }

  // When a bidder places a bid or updates their existing bid, they will use this function.
  // - total value can never be lowered
  // - unit price can never be lowered
  // - quantity can be raised or lowered, but only if unit price is raised to meet or exceed previous total price
  function placeBid(uint256 quantity, uint256 unitPrice) external payable whenNotPaused whenAuctionActive {
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
    require(finalUnitPrice % unitPriceStepSize == 0, "Unit price step too small.");

    // Reject bids that don't have a quantity within the valid range.
    require(finalQuantity >= minimumQuantity, "Quantity too low.");
    require(finalQuantity <= maximumQuantity, "Quantity too high.");

    // Total value can never be lowered.
    require(finalTotalValue >= initialTotalValue, "Total value can't be lowered.");

    // Unit price can never be lowered.
    // Quantity can be raised or lowered, but it can only be lowered if the unit price is raised to meet or exceed the initial total value. Ensuring the the unit price is never lowered takes care of this.
    require(finalUnitPrice >= initialUnitPrice, "Unit price can't be lowered.");

    // Ensure the new totalValue equals quantity * the unit price that was given in this txn exactly. This is important to prevent rounding errors later when returning ether.
    require(finalQuantity * finalUnitPrice == finalTotalValue, "Quantity * Unit Price != Total Value");

    // Unit price must be greater than or equal to the minimumUnitPrice.
    require(finalUnitPrice >= minimumUnitPrice, "Bid unit price too low.");

    // Something must be changing from the initial bid for this new bid to be valid.
    if (initialUnitPrice == finalUnitPrice && initialQuantity == finalQuantity) {
      revert("This bid doesn't change anything.");
    }

    // Update the bidder's bid.
    _bids[msg.sender].unitPrice = finalUnitPrice;
    _bids[msg.sender].quantity = finalQuantity;

    emit BidPlaced(_auctionIDCounter.current(), msg.sender, _bidPlacedCounter.current(), finalUnitPrice, finalQuantity);
    // Increment after emitting the BidPlaced event because counter is 0-indexed.
    _bidPlacedCounter.increment();
  }

  // Handles receiving ether to the contract.
  // Reject all direct payments to the contract except from beneficiary and owner.
  // Bids must be placed using the placeBid function.
  receive() external payable {
    require(msg.value > 0, "No ether was sent.");
    require(msg.sender == beneficiaryAddress || msg.sender == owner(), "Only owner or beneficiary can fund contract.");
  }
}
