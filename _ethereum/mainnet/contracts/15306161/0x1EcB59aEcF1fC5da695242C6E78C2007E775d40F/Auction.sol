// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 *
 * @dev Auction.sol - Metadrop auction implementation for Webaverse.
 *      Price non-discriminating auction with the following features:
 *      - Time based random end
 *      - Capped end (floor price)
 *
 */

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./Pausable.sol";
import "./MerkleProof.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

contract Auction is Ownable, Pausable, VRFConsumerBaseV2 {
  using SafeERC20 for IERC20;

  /**
   * @dev Chainlink config.
   */
  VRFCoordinatorV2Interface public vrfCoordinator;
  uint64 public vrfSubscriptionId;
  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  bytes32 public vrfKeyHash;
  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
  // so 100,000 is a safe default for this example contract. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
  uint32 public vrfCallbackGasLimit = 150000;
  // The default is 3, but you can set this higher.
  uint16 public vrfRequestConfirmations = 3;
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 public vrfNumWords = 1;

  /**
   * @dev Contract constants.
   */
  // Total auction length - including the last X hours inside which it can randomly end
  uint256 public constant AUCTION_LENGTH_IN_HOURS = 24;
  // Auction randomly ends within last AUCTION_END_THRESHOLD_HRS
  uint256 public constant AUCTION_END_THRESHOLD_HRS = 2;
  // Fixed minimum and maximum quantity
  uint256 public constant MINIMUM_QUANTITY = 1;
  uint256 public constant MAXIMUM_QUANTITY = 50;

  // Width of the window for which 1 random number will be requested
  uint256 public constant WINDOW_WIDTH_SECONDS = 60;
  // Probability of the random number ending the time based auction segment, out of 10,000
  uint256 public constant TIME_ENDING_P = 200; // 200 / 10,000 = 2%
  // The last time we called chainlink vrf for randomness to end the auction
  uint256 public lastRequestedRandomness;

  /**
   * @dev Contract immutable vars set in constructor.
   */
  uint256 public immutable minimumUnitPrice;
  uint256 public immutable maximumUnitPrice;
  uint256 public immutable minimumBidIncrement;
  uint256 public immutable unitPriceStepSize;

  uint256 public immutable numberOfAuctions;
  uint256 public immutable itemsPerAuction;
  address payable public immutable beneficiaryAddress;

  // block timestamp of when auction starts
  uint256 public auctionStart;
  // Merkle root of those addresses owed a refund
  bytes32 public refundMerkleRoot;

  AuctionStatus private _auctionStatus;
  uint256 private _bidIndex;

  uint256 public quantityAtMaxPrice;

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
  event RefundIssued(address indexed refundRecipient, uint256 refundAmount);

  event RandomEnd(
    string endType,
    uint256 endingProbability,
    uint256 randomNumber,
    string result
  );

  event RandomNumberReceived(uint256 indexed requestId, uint256 randomNumber);

  struct Bid {
    uint128 unitPrice;
    uint128 quantity;
  }

  struct AuctionStatus {
    bool started;
    bool ended;
  }

  // keccak256(auctionIndex, bidder address) => current bid
  mapping(bytes32 => Bid) private _bids;
  //Refunds address => excessRefunded
  mapping(address => bool) private _excessRefunded;

  /**
   *
   * @dev Constructor: The constructor must be passed the configuration items as
   * detailed below.
   *
   *   - floorEndTriggerPrice: The floor price that will trigger the floor based immediate end
   *   - vrfCoordinator: The VRF coordinator contract.
   *   - vrfKeyHash: The VRF key hash.
   */
  constructor(
    // Beneficiary address cannot be changed after deployment.
    address payable beneficiaryAddress_,
    uint256 minimumUnitPrice_,
    uint256 minimumBidIncrement_,
    uint256 unitPriceStepSize_,
    uint256 numberOfAuctions_,
    uint256 itemsPerAuction_,
    uint256 maximumUnitPrice_,
    address vrfCoordinator_,
    bytes32 vrfKeyHash_
  ) VRFConsumerBaseV2(vrfCoordinator_) {
    beneficiaryAddress = beneficiaryAddress_;
    minimumUnitPrice = minimumUnitPrice_;
    maximumUnitPrice = maximumUnitPrice_;
    minimumBidIncrement = minimumBidIncrement_;
    unitPriceStepSize = unitPriceStepSize_;
    numberOfAuctions = numberOfAuctions_;
    itemsPerAuction = itemsPerAuction_;
    vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator_);
    vrfKeyHash = vrfKeyHash_;
    pause();
  }

  modifier whenRefundsActive() {
    require(refundMerkleRoot != 0, "Refund merkle root not set");
    _;
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

  /**
   *
   * @dev auctionStatus: Return the current status of the auction.
   *      bool started
   *      bool ended
   *
   */
  function auctionStatus() public view returns (AuctionStatus memory) {
    return _auctionStatus;
  }

  /**
   *
   * @dev chainlink configuration setters:
   *
   */

  /**
   *
   * @dev setVRFCoordinator: Set the chainlink subscription vrf coordinator.
   *
   */
  function setVRFCoordinator(address vrfCoordinator_) external onlyOwner {
    vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator_);
  }

  /**
   *
   * @dev setVRFSubscriptionId: Set the chainlink subscription id.
   *
   */
  function setVRFSubscriptionId(uint64 vrfSubscriptionId_) external onlyOwner {
    vrfSubscriptionId = vrfSubscriptionId_;
  }

  /**
   *
   * @dev setVRFKeyHash: Set the chainlink keyhash (gas lane).
   *
   */
  function setVRFKeyHash(bytes32 vrfKeyHash_) external onlyOwner {
    vrfKeyHash = vrfKeyHash_;
  }

  /**
   *
   * @dev setVRFCallbackGasLimit: Set the chainlink callback gas limit.
   *
   */
  function setVRFCallbackGasLimit(uint32 vrfCallbackGasLimit_)
    external
    onlyOwner
  {
    vrfCallbackGasLimit = vrfCallbackGasLimit_;
  }

  /**
   *
   * @dev set: Set the chainlink number of confirmations.
   *
   */
  function setVRFRequestConfirmations(uint16 vrfRequestConfirmations_)
    external
    onlyOwner
  {
    vrfRequestConfirmations = vrfRequestConfirmations_;
  }

  /**
   *
   * @dev setVRFNumWords: Set the chainlink number of words.
   *
   */
  function setVRFNumWords(uint32 vrfNumWords_) external onlyOwner {
    vrfNumWords = vrfNumWords_;
  }

  /**
   *
   * @dev pause: Pause the contract.
   *
   */
  function pause() public onlyOwner {
    _pause();
  }

  /**
   *
   * @dev pause: Unpause the contract.
   *
   */
  function unpause() public onlyOwner {
    _unpause();
  }

  /**
   *
   * @dev startAuction: set the auction to started and unpause functionality.
   *
   */
  function startAuction() external onlyOwner whenPreAuction {
    _auctionStatus.started = true;
    auctionStart = block.timestamp;

    if (paused()) {
      unpause();
    }
    emit AuctionStarted();
  }

  /**
   *
   * @dev getAuctionEnd: get the time at which the auction will end, being the
   * start time plus the configured auction length in hours.
   *
   */
  function getAuctionEnd() internal view returns (uint256) {
    return auctionStart + (AUCTION_LENGTH_IN_HOURS * 1 hours);
  }

  /**
   *
   * @dev endAuction: external function that can be called to execute _endAuction
   * when the block.timestamp exceeds the auction end time (i.e. the auction is over).
   *
   */
  function endAuction() external whenAuctionActive {
    require(
      block.timestamp >= getAuctionEnd(),
      "Auction can't be stopped until due"
    );
    _endAuction();
  }

  /**
   *
   * @dev _endAuction: internal function that sets _auctionStatus.ended to be true
   * and pauses the contract.
   *
   */
  function _endAuction() internal whenAuctionActive {
    _auctionStatus.ended = true;
    if (!paused()) {
      _pause();
    }
    emit AuctionEnded();
  }

  /**
   *
   * @dev numberOfBidsPlaced: returns the _bidIndex which is the total
   * number of bids made to the auction(s) being run by this contract.
   *
   */
  function numberOfBidsPlaced() external view returns (uint256) {
    return _bidIndex;
  }

  /**
   *
   * @dev getBid: returns the _bidIndex which is the total
   * number of bids made to the auction(s) being run by this contract.
   *
   */
  function getBid(uint256 auctionIndex_, address bidder_)
    external
    view
    returns (Bid memory)
  {
    return _bids[_bidHash(auctionIndex_, bidder_)];
  }

  /**
   *
   * @dev _bidHash: creates a hash of the auctionIndex and bidder address
   * in order to return the bid for a specific auction ID for the passed address.
   *
   */
  function _bidHash(uint256 auctionIndex_, address bidder_)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(auctionIndex_, bidder_));
  }

  /**
   *
   * @dev _refundHash: creates a hash of the refundAmount and bidder address
   *
   */
  function _refundHash(uint256 refundAmount_, address bidder_)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(refundAmount_, bidder_));
  }

  /**
   *
   * @dev placeBid:
   *
   * When a bidder places a bid or updates their existing bid, they will use this function.
   * - total value can never be lowered
   * - unit price can never be lowered
   * - quantity can be raised or lowered, but only if unit price is raised to meet or exceed previous total price
   *
   */
  function placeBid(
    uint256 auctionIndex_,
    uint256 quantity_,
    uint256 unitPrice_
  ) external payable whenAuctionActive whenNotPaused {
    // If the bidder is increasing their bid, the amount being added must be greater than or equal to the minimum bid increment.
    if (msg.value > 0 && msg.value < minimumBidIncrement) {
      revert("Bid lower than minimum bid increment.");
    }
    // Ensure auctionIndex is within valid range.
    require(auctionIndex_ < numberOfAuctions, "Invalid auctionIndex");

    // Cache initial bid values.
    bytes32 bidHash = _bidHash(auctionIndex_, msg.sender);
    uint256 initialUnitPrice = _bids[bidHash].unitPrice;
    uint256 initialQuantity = _bids[bidHash].quantity;
    uint256 initialBalance = initialUnitPrice * initialQuantity;

    // Cache final bid values.
    uint256 finalUnitPrice = unitPrice_;
    uint256 finalQuantity = quantity_;
    uint256 finalBalance = initialBalance + msg.value;

    // Don't allow bids with a unit price scale smaller than unitPriceStepSize.
    // For example, allow 1.01 or 111.01 but don't allow 1.011.
    require(
      finalUnitPrice % unitPriceStepSize == 0,
      "Unit price step too small"
    );

    // Reject bids that don't have a quantity within the valid range.
    require(finalQuantity >= MINIMUM_QUANTITY, "Quantity too low");
    require(finalQuantity <= MAXIMUM_QUANTITY, "Quantity too high");

    // Balance can never be lowered.
    require(finalBalance >= initialBalance, "Balance can't be lowered");

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

    // Unit price must be less than or equal to the maximumUnitPrice.
    require(finalUnitPrice <= maximumUnitPrice, "Bid unit price too high");

    // Something must be changing from the initial bid for this new bid to be valid.
    if (
      initialUnitPrice == finalUnitPrice && initialQuantity == finalQuantity
    ) {
      revert("This bid doesn't change anything");
    }

    // If the bid is the max then increment the counter of max bids by the quantity on the bid:
    if (finalUnitPrice == maximumUnitPrice) {
      quantityAtMaxPrice += finalQuantity;
    }

    // Update the bidder's bid.
    _bids[bidHash].unitPrice = uint128(finalUnitPrice);
    _bids[bidHash].quantity = uint128(finalQuantity);

    emit BidPlaced(
      bidHash,
      auctionIndex_,
      msg.sender,
      _bidIndex,
      finalUnitPrice,
      finalQuantity,
      finalBalance
    );
    // Increment after emitting the BidPlaced event because counter is 0-indexed.
    _bidIndex += 1;

    // After the bid has been placed, check to see whether the auction is ended
    _checkAuctionEnd();
  }

  /**
   *
   * @dev withdrawContractBalance: onlyOwner withdrawal to the beneficiary address
   *
   */
  function withdrawContractBalance() external onlyOwner {
    (bool success, ) = beneficiaryAddress.call{value: address(this).balance}(
      ""
    );
    require(success, "Transfer failed");
  }

  /**
   *
   * @dev withdrawETH: onlyOwner withdrawal to the beneficiary address, sending
   * the amount to withdraw as an argument
   *
   */
  function withdrawETH(uint256 amount_) external onlyOwner {
    (bool success, ) = beneficiaryAddress.call{value: amount_}("");
    require(success, "Transfer failed");
  }

  /**
   *
   * @dev transferERC20Token:   A withdraw function to avoid locking ERC20 tokens
   * in the contract forever. Tokens can only be withdrawn by the owner, to the owner.
   *
   */
  function transferERC20Token(IERC20 token, uint256 amount) public onlyOwner {
    token.safeTransfer(owner(), amount);
  }

  /**
   *
   * @dev receive: Handles receiving ether to the contract.
   * Reject all direct payments to the contract except from beneficiary and owner.
   * Bids must be placed using the placeBid function.
   *
   */
  receive() external payable {
    require(msg.value > 0, "No ether was sent");
    require(
      msg.sender == beneficiaryAddress || msg.sender == owner(),
      "Only owner or beneficiary can fund contract"
    );
  }

  /**
   *
   * @dev setRefundMerkleRoot: onlyOwner call to set the refund merkleroot.
   *
   */
  function setRefundMerkleRoot(bytes32 refundMerkleRoot_)
    external
    onlyOwner
    whenAuctionEnded
  {
    refundMerkleRoot = refundMerkleRoot_;
  }

  /**
   *
   * @dev claimRefund: external function call to allow bidders to claim refunds.
   *
   */
  function claimRefund(uint256 refundAmount_, bytes32[] calldata proof_)
    external
    whenNotPaused
    whenAuctionEnded
    whenRefundsActive
  {
    // Can only refund if we haven't already refunded this address:
    require(!_excessRefunded[msg.sender], "Refund already issued");

    bytes32 leaf = _refundHash(refundAmount_, msg.sender);
    require(
      MerkleProof.verify(proof_, refundMerkleRoot, leaf),
      "Refund proof invalid"
    );

    // Safety check - we shouldn't be refunding more than this address has bid across all auctions. This will also
    // catch data collision exploits using other address and refund amount combinations, if
    // such are possible:
    uint256 totalBalance;
    for (
      uint256 auctionIndex = 0;
      auctionIndex < numberOfAuctions;
      auctionIndex++
    ) {
      bytes32 bidHash = _bidHash(auctionIndex, msg.sender);
      totalBalance += _bids[bidHash].unitPrice * _bids[bidHash].quantity;
    }

    require(refundAmount_ <= totalBalance, "Refund request exceeds balance");

    // Set state - we are issuing a refund to this address now, therefore
    // this logic path cannot be entered again for this address:
    _excessRefunded[msg.sender] = true;

    // State has been set, we can now send the refund:
    (bool success, ) = msg.sender.call{value: refundAmount_}("");
    require(success, "Refund failed");

    emit RefundIssued(msg.sender, refundAmount_);
  }

  /**
   *
   * @dev randomEndStarted: Has a random end commenced?
   * This doesn't check for auction end as it is covered by thresholdReached
   *
   */
  function randomEndStarted() external view returns (bool randomEndStarted_) {
    return _thresholdReached();
  }

  /**
   *
   * @dev _blindPriceReached: Has the floor price end trigger been reached?
   *
   */
  function _blindPriceReached() internal view returns (bool) {
    return quantityAtMaxPrice >= itemsPerAuction;
  }

  /**
   *
   * @dev _thresholdReached: Has the auction time based random end period been reached?
   *
   */
  function _thresholdReached() internal view returns (bool) {
    return
      block.timestamp >=
      (getAuctionEnd() - (AUCTION_END_THRESHOLD_HRS * 1 hours));
  }

  /**
   *
   * @dev _checkAuctionEnd: Check if the auction should end based on:
   *  - The time being up (block timestamp is past the end of the auction time)
   *  - The floor price trigger has been reached
   *  - We are in the random end period at the end of the contract and need to call a
   *    random end check
   *
   */
  function _checkAuctionEnd() internal {
    // (1) If we are at or past the end time it's the end of the action:
    if (block.timestamp >= getAuctionEnd())
      _endAuction();
      // (2) See if we have hit the floor trigger price, if so we end the auction
    else if (_blindPriceReached()) {
      _endAuction();
    }
    // (3) See if we have entered the random end period based on time:
    // Also make sure we haven't already requested randomness within WINDOW_WIDTH_SECONDS from now
    else if (
      _thresholdReached() &&
      (block.timestamp - lastRequestedRandomness) >= WINDOW_WIDTH_SECONDS
    ) {
      lastRequestedRandomness = block.timestamp;
      _requestRandomWords();
    }
  }

  /**
   *
   * @dev _requestRandomWords: Request randomness from chainlinkv2
   * Assumes the subscription is funded sufficiently.
   */
  function _requestRandomWords() private returns (uint256) {
    // Will revert if subscription is not set and funded.
    return
      vrfCoordinator.requestRandomWords(
        vrfKeyHash,
        vrfSubscriptionId,
        vrfRequestConfirmations,
        vrfCallbackGasLimit,
        vrfNumWords
      );
  }

  /**
   *
   * @dev fulfillRandomWords: Callback from the chainlinkv2 oracle with randomness.
   * Checks to end the auction if it's in the random end period of price or time.
   */
  function fulfillRandomWords(uint256 requestId_, uint256[] memory randomWords_)
    internal
    override
  {
    uint256 randomness = randomWords_[0] % 10000;
    emit RandomNumberReceived(requestId_, randomWords_[0]);

    if (_thresholdReached()) {
      if (randomness < TIME_ENDING_P) {
        emit RandomEnd(
          "Time",
          TIME_ENDING_P,
          randomness,
          "Random End: ending now"
        );
        _endAuction();
      } else {
        emit RandomEnd(
          "Time",
          TIME_ENDING_P,
          randomness,
          "Random End: continuing"
        );
      }
    }
  }
}
