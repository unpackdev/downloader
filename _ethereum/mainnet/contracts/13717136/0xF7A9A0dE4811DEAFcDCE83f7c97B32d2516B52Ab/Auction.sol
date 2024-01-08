// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "./Ownable.sol";
import "./AccessControl.sol";
import "./Pausable.sol";
import "./Counters.sol";
import "./VRFConsumerBase.sol";

contract Auction is Ownable, Pausable, VRFConsumerBase {
  using Counters for Counters.Counter;

  uint256 public immutable minimumUnitPrice;
  uint256 public immutable minimumBidIncrement;
  uint256 public immutable unitPriceStepSize;
  uint256 public immutable minimumQuantity;
  uint256 public immutable maximumQuantity;
  uint256 public immutable numberOfAuctions;
  uint256 public immutable itemsPerAuction;
  address payable public immutable beneficiaryAddress;

  uint256 public lastRandomNumber;

  // Auction ends in last 3hrs when this random number is observed
  uint256 constant auctionLengthInHours = 72;
  // The target number for the random end's random number generator
  uint256 constant randomEnd = 3;
  // block timestamp of when auction starts
  uint256 public auctionStart;

  AuctionStatus private _auctionStatus;
  Counters.Counter private _bidIndex;

  // Chainlink configuration.
  bytes32 internal keyHash;
  uint256 internal fee;

  event AuctionStarted();
  event AuctionEnded();
  event BidPlaced(
    bytes32 indexed bidHash,
    uint256 indexed auctionIndex,
    address indexed bidder,
    uint256 bidIndex,
    uint256 unitPrice,
    uint256 quantity,
    uint256 balance
  );
  event WinnerSelected(
    uint256 indexed auctionIndex,
    address indexed bidder,
    uint256 unitPrice,
    uint256 quantity
  );
  event BidderRefunded(
    uint256 indexed auctionIndex,
    address indexed bidder,
    uint256 refundAmount
  );

  struct Bid {
    uint256 unitPrice;
    uint256 quantity;
    uint256 balance;
  }

  struct AuctionStatus {
    bool started;
    bool ended;
  }

  // keccak256(auctionIndex, bidder address) => current bid
  mapping(bytes32 => Bid) private _bids;
  // auctionID => remainingItemsPerAuction
  mapping(uint256 => uint256) private _remainingItemsPerAuction;

  // Beneficiary address cannot be changed after deployment.
  constructor(
    address payable _beneficiaryAddress,
    uint256 _minimumUnitPrice,
    uint256 _minimumBidIncrement,
    uint256 _unitPriceStepSize,
    uint256 _maximumQuantity,
    uint256 _numberOfAuctions,
    uint256 _itemsPerAuction,
    address vrfCoordinator_,
    address link_,
    bytes32 keyHash_,
    uint256 fee_
  ) VRFConsumerBase(vrfCoordinator_, link_) {
    beneficiaryAddress = _beneficiaryAddress;
    minimumUnitPrice = _minimumUnitPrice;
    minimumBidIncrement = _minimumBidIncrement;
    unitPriceStepSize = _unitPriceStepSize;
    minimumQuantity = 1;
    maximumQuantity = _maximumQuantity;
    numberOfAuctions = _numberOfAuctions;
    itemsPerAuction = _itemsPerAuction;

    keyHash = keyHash_;
    fee = fee_;

    // Set up the _remainingItemsPerAuction tracker.
    for (uint256 i = 0; i < _numberOfAuctions; i++) {
      _remainingItemsPerAuction[i] = _itemsPerAuction;
    }
    pause();
  }

  modifier whenAuctionActive() {
    require(!_auctionStatus.ended, "Auction has already ended");
    require(_auctionStatus.started, "Auction hasn't started yet");
    _;
  }

  modifier whenPreAuction() {
    require(!_auctionStatus.ended, "Auction has already ended");
    require(!_auctionStatus.started, "Auction has already started");
    _;
  }

  modifier whenAuctionEnded() {
    require(_auctionStatus.ended, "Auction hasn't ended yet");
    require(_auctionStatus.started, "Auction hasn't started yet");
    _;
  }

  function auctionStatus() public view returns (AuctionStatus memory) {
    return _auctionStatus;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function startAuction() external onlyOwner whenPreAuction {
    _auctionStatus.started = true;
    auctionStart = block.timestamp;

    if (paused()) {
      unpause();
    }
    emit AuctionStarted();
  }

  function endAuction() external onlyOwner whenAuctionActive {
    require(
      block.timestamp >= (auctionStart + auctionLengthInHours * 60 * 60),
      "Auction can't be stopped until due"
    );
    _endAuction();
  }

  function _endAuction() internal whenAuctionActive {
    _auctionStatus.ended = true;
    emit AuctionEnded();
  }

  // Requests randomness.
  function getRandomNumber() internal returns (bytes32 requestId) {
    require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
    return requestRandomness(keyHash, fee);
  }

  // Callback function used by VRF Coordinator.
  function fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal
    override
  {
    lastRandomNumber = randomness;
    if (randomness % 20 == randomEnd) {
      _endAuction();
    }
  }

  function attemptEndAuction() external onlyOwner whenAuctionActive {
    getRandomNumber();
  }

  function numberOfBidsPlaced() external view returns (uint256) {
    return _bidIndex.current();
  }

  function getBid(uint256 auctionIndex, address bidder)
    external
    view
    returns (Bid memory)
  {
    return _bids[_bidHash(auctionIndex, bidder)];
  }

  function getRemainingItemsForAuction(uint256 auctionIndex)
    external
    view
    returns (uint256)
  {
    require(auctionIndex < numberOfAuctions, "Invalid auctionIndex");
    return _remainingItemsPerAuction[auctionIndex];
  }

  function _bidHash(uint256 auctionIndex_, address bidder_)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encode(auctionIndex_, bidder_));
  }

  function selectWinners(
    uint256 auctionIndex_,
    address[] calldata bidders_,
    uint256[] calldata quantities_
  ) external onlyOwner whenPaused whenAuctionEnded {
    // Ensure auctionIndex is within valid range.
    require(auctionIndex_ < numberOfAuctions, "Invalid auctionIndex");
    require(
      bidders_.length == quantities_.length,
      "bidders length doesn't match quantities length"
    );

    uint256 tmpRemainingItemsPerAuction = _remainingItemsPerAuction[
      auctionIndex_
    ];
    // Iterate over each winning address until we reach the end of the winners list or we deplete _remainingItemsPerAuction for this auctionIndex_.
    for (uint256 i = 0; i < bidders_.length; i++) {
      address bidder = bidders_[i];
      uint256 quantity = quantities_[i];

      bytes32 bidHash = _bidHash(auctionIndex_, bidder);
      uint256 bidUnitPrice = _bids[bidHash].unitPrice;
      uint256 maxAvailableQuantity = _bids[bidHash].quantity;

      // Skip bidders whose remaining bid quantity is already 0, or who have function input quantity set to 0.
      if (maxAvailableQuantity == 0 || quantity == 0) {
        continue;
      }

      require(
        quantity >= maxAvailableQuantity,
        "quantity is greater than max quantity"
      );

      if (tmpRemainingItemsPerAuction == quantity) {
        // STOP: _remainingItemsPerAuction has been depleted, and the quantity for this bid made us hit 0 exactly.
        _bids[bidHash].quantity = 0;
        emit WinnerSelected(auctionIndex_, bidder, bidUnitPrice, quantity);
        _remainingItemsPerAuction[auctionIndex_] = 0;
        return;
      } else if (tmpRemainingItemsPerAuction < quantity) {
        // STOP: _remainingItemsPerAuction has been depleted, and the quantity for this bid made us go negative (quantity too high to give the bidder all they asked for)
        emit WinnerSelected(
          auctionIndex_,
          bidder,
          bidUnitPrice,
          tmpRemainingItemsPerAuction
        );
        // Don't set unitPrice to 0 here as there is still at least 1 quantity remaining.
        // Must set _remainingItemsPerAuction to 0 AFTER this.
        _bids[bidHash].quantity -= tmpRemainingItemsPerAuction;
        _remainingItemsPerAuction[auctionIndex_] = 0;
        return;
      } else {
        // CONTINUE: _remainingItemsPerAuction hasn't been depleted yet...
        _bids[bidHash].quantity = 0;
        emit WinnerSelected(auctionIndex_, bidder, bidUnitPrice, quantity);
        tmpRemainingItemsPerAuction -= quantity;
      }
    }
    // If reached this point, _remainingItemsPerAuction hasn't been depleted but we've run out of bidders to select as winners. Set the final storage value.
    _remainingItemsPerAuction[auctionIndex_] = tmpRemainingItemsPerAuction;
  }

  // Refunds losing bidders from the contract's balance.
  function partiallyRefundBidders(
    uint256 auctionIndex_,
    address payable[] calldata bidders_,
    uint256[] calldata amounts_
  ) external onlyOwner whenPaused whenAuctionEnded {
    require(
      bidders_.length == amounts_.length,
      "bidders length doesn't match amounts length"
    );

    for (uint256 i = 0; i < bidders_.length; i++) {
      address payable bidder = bidders_[i];
      uint256 refundAmount = amounts_[i];
      bytes32 bidHash = _bidHash(auctionIndex_, bidder);
      uint256 refundMaximum = _bids[bidHash].balance;

      require(
        refundAmount <= refundMaximum,
        "Refund amount is greater than balance"
      );

      // Skip bidders who aren't entitled to a refund.
      if (refundAmount == 0 || refundMaximum == 0) {
        continue;
      }

      _bids[bidHash].balance -= refundAmount;
      (bool success, ) = bidder.call{value: refundAmount}("");
      require(success, "Transfer failed.");
      emit BidderRefunded(auctionIndex_, bidder, refundAmount);
    }
  }

  // When a bidder places a bid or updates their existing bid, they will use this function.
  // - total value can never be lowered
  // - unit price can never be lowered
  // - quantity can be raised or lowered, but only if unit price is raised to meet or exceed previous total price
  function placeBid(
    uint256 auctionIndex,
    uint256 quantity,
    uint256 unitPrice
  ) external payable whenNotPaused whenAuctionActive {
    // If the bidder is increasing their bid, the amount being added must be greater than or equal to the minimum bid increment.
    if (msg.value > 0 && msg.value < minimumBidIncrement) {
      revert("Bid lower than minimum bid increment.");
    }

    // Ensure auctionIndex is within valid range.
    require(auctionIndex < numberOfAuctions, "Invalid auctionIndex");

    // Cache initial bid values.
    bytes32 bidHash = _bidHash(auctionIndex, msg.sender);
    uint256 initialUnitPrice = _bids[bidHash].unitPrice;
    uint256 initialQuantity = _bids[bidHash].quantity;
    uint256 initialBalance = _bids[bidHash].balance;

    // Cache final bid values.
    uint256 finalUnitPrice = unitPrice;
    uint256 finalQuantity = quantity;
    uint256 finalBalance = initialBalance + msg.value;

    // Don't allow bids with a unit price scale smaller than unitPriceStepSize.
    // For example, allow 1.01 or 111.01 but don't allow 1.011.
    require(
      finalUnitPrice % unitPriceStepSize == 0,
      "Unit price step too small"
    );

    // Reject bids that don't have a quantity within the valid range.
    require(finalQuantity >= minimumQuantity, "Quantity too low");
    require(finalQuantity <= maximumQuantity, "Quantity too high");

    // Total value can never be lowered.
    require(finalBalance >= initialBalance, "Total value can't be lowered");

    // Unit price can never be lowered.
    // Quantity can be raised or lowered, but it can only be lowered if the unit price is raised to meet or exceed the initial total value. Ensuring the the unit price is never lowered takes care of this.
    require(finalUnitPrice >= initialUnitPrice, "Unit price can't be lowered");

    // Ensure the new finalBalance equals quantity * the unit price that was given in this txn exactly. This is important to prevent rounding errors later when returning ether.
    require(
      finalQuantity * finalUnitPrice == finalBalance,
      "Quantity * Unit Price != Total Value"
    );

    // Unit price must be greater than or equal to the minimumUnitPrice.
    require(finalUnitPrice >= minimumUnitPrice, "Bid unit price too low");

    // Something must be changing from the initial bid for this new bid to be valid.
    if (
      initialUnitPrice == finalUnitPrice && initialQuantity == finalQuantity
    ) {
      revert("This bid doesn't change anything");
    }

    // Update the bidder's bid.
    _bids[bidHash].unitPrice = finalUnitPrice;
    _bids[bidHash].quantity = finalQuantity;
    _bids[bidHash].balance = finalBalance;

    emit BidPlaced(
      bidHash,
      auctionIndex,
      msg.sender,
      _bidIndex.current(),
      finalUnitPrice,
      finalQuantity,
      _bids[bidHash].balance
    );
    // Increment after emitting the BidPlaced event because counter is 0-indexed.
    _bidIndex.increment();
  }

  function withdrawContractBalance() external onlyOwner {
    (bool success, ) = beneficiaryAddress.call{value: address(this).balance}(
      ""
    );
    require(success, "Transfer failed");
  }

  // Handles receiving ether to the contract.
  // Reject all direct payments to the contract except from beneficiary and owner.
  // Bids must be placed using the placeBid function.
  receive() external payable {
    require(msg.value > 0, "No ether was sent");
    require(
      msg.sender == beneficiaryAddress || msg.sender == owner(),
      "Only owner or beneficiary can fund contract"
    );
  }
}
