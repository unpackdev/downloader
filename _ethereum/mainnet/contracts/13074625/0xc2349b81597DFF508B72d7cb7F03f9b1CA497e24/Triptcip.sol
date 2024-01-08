// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC721Burnable.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./ECDSA.sol";

contract Triptcip is
  ERC721Burnable,
  ERC721URIStorage,
  Ownable,
  Pausable,
  ReentrancyGuard
{
  using Counters for Counters.Counter;
  using ECDSA for bytes32;
  using SafeERC20 for IERC20;

  event CreateToken(
    uint256 timestamp,
    address indexed owner,
    uint256 indexed tokenId,
    uint256 royalty,
    string metadataId
  );

  event AuctionCreate(
    uint256 timestamp,
    address indexed owner,
    uint256 indexed tokenId,
    uint256 reservePrice
  );

  event AuctionPlaceBid(
    uint256 timestamp,
    address indexed owner,
    uint256 indexed tokenId,
    uint256 amount,
    uint256 deadline
  );

  event AcceptOffer(
    uint256 timestamp,
    address bidder,
    uint256 tokenId,
    uint256 amount,
    uint256 deadline
  );

  event PlaceBidRefund(
    uint256 timestamp,
    uint256 indexed tokenId,
    address indexed bidder,
    uint256 amount
  );

  event AuctionClaim(
    uint256 timestamp,
    address indexed owner,
    uint256 indexed tokenId
  );

  struct Bid {
    address bidder;
    uint256 amount;
    uint256 timestamp;
  }

  struct WinningBid {
    uint256 amount;
    address bidder;
  }

  struct Auction {
    address seller;
    uint256 reservePrice;
    bool isClaimed;
    uint256 deadline;
    WinningBid winningBid;
    Bid[] bids;
  }

  address private serviceWallet;

  uint private constant BP_DIVISOR = 10000;
  uint256 private serviceFee;
  mapping(uint256 => uint256) private royaltyFees;

  address public wethAddress;
  uint256 private deadlineInSeconds;
  uint256 public timeBuffer;
  uint256 public minBidIncrease;

  mapping(uint256 => Auction) public auctions;
  mapping(uint256 => address) private tokenMinters;

  Counters.Counter private tokenIdCounter;
  string private baseTokenURI;

  uint private minReservePrice = 0.1 ether;

  mapping(address => mapping(uint256 => bool)) private nonces;

  modifier onlyAuctionedToken(uint256 _tokenId) {
    require(auctions[_tokenId].seller != address(0), "Does not exist");
    _;
  }

  modifier onlyTokenOwner(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender, "Not the owner");
    _;
  }

  modifier onlyEOA() {
    require(msg.sender == tx.origin, "No contract calls");
    _;
  }

  constructor(
    address _serviceWallet,
    uint256 _serviceFee,
    uint256 _deadlineInSeconds,
    string memory _baseTokenURI,
    address _wethAddress
  ) ERC721("Triptcip", "TRIP") onlyEOA {
    require(_serviceWallet != address(0), "_serviceWallet required");
    require(_serviceFee > 0, "_serviceFee invalid");
    require(_serviceFee < BP_DIVISOR, "_serviceFee invalid");

    baseTokenURI = _baseTokenURI;
    serviceWallet = _serviceWallet;
    serviceFee = _serviceFee;
    wethAddress = _wethAddress;
    deadlineInSeconds = _deadlineInSeconds;
    timeBuffer = 15 * 60; // Extend 15 minutes after every bid is made in last 15 minutes
    minBidIncrease = 1000; // Minimum 10% every bid
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function updateBaseTokenURI(string memory _baseURI) public onlyOwner {
    baseTokenURI = _baseURI;
  }

  function updateTimeBuffer(uint256 _timeBuffer) public onlyOwner {
    timeBuffer = _timeBuffer;
  }

  function updateMinBidIncreasePercentage(uint256 _minBidIncrease)
    public
    onlyOwner
  {
    minBidIncrease = _minBidIncrease;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  function getMinter(uint256 _tokenId) external view returns (address) {
    return tokenMinters[_tokenId];
  }

  function getRoyalty(uint256 _tokenId) external view returns (uint256) {
    return royaltyFees[_tokenId];
  }

  function updateDeadline(uint256 _deadlineInSeconds) public onlyOwner {
    deadlineInSeconds = _deadlineInSeconds;
  }

  function getDeadlineInSeconds() public view onlyOwner returns (uint256) {
    return deadlineInSeconds;
  }

  function updateServiceFee(uint256 _serviceFee) public onlyOwner {
    require(_serviceFee > 0, "_serviceFee invalid");
    require(_serviceFee < BP_DIVISOR, "_serviceFee invalid");

    serviceFee = _serviceFee;
  }

  function getServiceFee() public view onlyOwner returns (uint256) {
    return serviceFee;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function setMinReservePrice(uint256 _minReservePrice) external onlyOwner {
    minReservePrice = _minReservePrice;
  }

  function createToken(uint256 _royalty, string calldata metadataId)
    public
    onlyEOA
    returns (uint256)
  {
    require(_royalty < BP_DIVISOR - serviceFee, "_royalty invalid");

    tokenIdCounter.increment();

    uint256 newTokenId = tokenIdCounter.current();
    _mint(msg.sender, newTokenId);

    royaltyFees[newTokenId] = _royalty;
    tokenMinters[newTokenId] = msg.sender;

    emit CreateToken(
      block.timestamp,
      msg.sender,
      newTokenId,
      _royalty,
      metadataId
    );

    return newTokenId;
  }

  function acceptOffer(
    uint256 _tokenId,
    uint256 _amount,
    uint256 _deadline,
    uint256 _nonce,
    address _signer,
    bytes memory _signature
  ) external onlyTokenOwner(_tokenId) {
    require(auctions[_tokenId].seller == address(0), "In auction");

    require(block.timestamp <= _deadline, "Offer expired");
    require(!nonces[_signer][_nonce], "Invalid nonce");

    require(
      keccak256(
        abi.encodePacked(_tokenId, _amount, _deadline, _nonce, address(this))
      ).toEthSignedMessageHash().recover(_signature) == _signer,
      "Invalid signer"
    );

    uint256 serviceFeeAmount = (_amount * serviceFee) / BP_DIVISOR;
    uint256 royaltyFeeAmount = (_amount * royaltyFees[_tokenId]) / BP_DIVISOR;

    // TODO: do we need to add "success" checks?

    // Pay the platform
    IERC20(wethAddress).safeTransferFrom(
      _signer,
      serviceWallet,
      serviceFeeAmount
    );

    // Pay the royalties
    IERC20(wethAddress).safeTransferFrom(
      _signer,
      tokenMinters[_tokenId],
      royaltyFeeAmount
    );

    // Pay the seller
    IERC20(wethAddress).safeTransferFrom(
      _signer,
      msg.sender,
      (_amount - serviceFeeAmount - royaltyFeeAmount)
    );

    // Transfer the token
    _safeTransfer(msg.sender, _signer, _tokenId, "");

    nonces[_signer][_nonce] = true;

    emit AcceptOffer(block.timestamp, msg.sender, _tokenId, _amount, _deadline);
  }

  function invalidateNonce(uint256 _nonce) external {
    nonces[msg.sender][_nonce] = true;
  }

  function auctionCreate(uint256 _tokenId, uint256 _reservePrice)
    public
    onlyTokenOwner(_tokenId)
    onlyEOA
  {
    Auction storage auction = auctions[_tokenId];

    require(
      _reservePrice >= minReservePrice,
      "`_reservePrice` must be at least minReservePrice"
    );
    require(auction.seller == address(0), "Duplicate");

    auction.seller = msg.sender;
    auction.reservePrice = _reservePrice;

    emit AuctionCreate(block.timestamp, msg.sender, _tokenId, _reservePrice);
  }

  function updateReservePrice(uint256 _tokenId, uint256 _reservePrice)
    public
    onlyAuctionedToken(_tokenId)
    onlyTokenOwner(_tokenId)
  {
    require(
      _reservePrice >= minReservePrice,
      "`_reservePrice` must be at least minReservePrice"
    );

    Auction storage auction = auctions[_tokenId];

    require(auction.bids.length == 0, "Bidding already started");

    auction.reservePrice = _reservePrice;
  }

  function auctionPlaceBid(uint256 _tokenId)
    public
    payable
    onlyAuctionedToken(_tokenId)
    onlyEOA
    nonReentrant
  {
    Auction storage auction = auctions[_tokenId];

    uint current = auction.winningBid.amount;

    require(msg.value >= auction.reservePrice, "Bid too low");
    require(
      msg.value >= current + 0.1 ether ||
        msg.value >= (current * (BP_DIVISOR + minBidIncrease)) / BP_DIVISOR,
      "Bid too low"
    );
    uint256 deadline = auction.deadline;
    require(block.timestamp < deadline || deadline == 0, "Auction is over");

    // This means, it's a fresh auction, no one has bid on it yet.
    if (deadline == 0) {
      // Start the deadline, it's set to NOW + 24 hours in seconds (86400)
      // Deadline should prob be a contract level constant, or configurable here
      auction.deadline = block.timestamp + deadlineInSeconds;
    } else if (deadline - block.timestamp <= timeBuffer) {
      // If within 15 minutes of expiry, extend with another 15 minutes
      auction.deadline = deadline + timeBuffer;
    }

    uint256 previousBids = auction.bids.length;

    auction.bids.push(Bid(msg.sender, msg.value, block.timestamp));
    auction.winningBid.amount = msg.value;
    auction.winningBid.bidder = msg.sender;

    // Refund previous bid
    if (previousBids > 0) {
      address previousBidder = auction.bids[previousBids - 1].bidder;
      uint256 previousBid = auction.bids[previousBids - 1].amount;

      previousBidder.call{value: previousBid}("");

      emit PlaceBidRefund(
        block.timestamp,
        _tokenId,
        previousBidder,
        previousBid
      );
    }

    emit AuctionPlaceBid(
      block.timestamp,
      msg.sender,
      _tokenId,
      msg.value,
      auction.deadline
    );
  }

  function auctionClaim(uint256 _tokenId)
    public
    onlyAuctionedToken(_tokenId)
    nonReentrant
  {
    Auction storage auction = auctions[_tokenId];

    require(block.timestamp > auction.deadline, "Auction not over");

    auction.isClaimed = true;

    uint256 salePrice = auction.winningBid.amount;
    uint256 serviceFeeAmount = (salePrice * serviceFee) / BP_DIVISOR;
    uint256 royaltyFeeAmount = (salePrice * royaltyFees[_tokenId]) / BP_DIVISOR;

    // Pay the platform
    serviceWallet.call{value: serviceFeeAmount}("");

    // Pay the royalty
    tokenMinters[_tokenId].call{value: royaltyFeeAmount}("");

    // Pay the seller
    auction.seller.call{value: salePrice - serviceFeeAmount - royaltyFeeAmount}(
      ""
    );

    address winner = auction.winningBid.bidder;

    delete auctions[_tokenId];

    _safeTransfer(ownerOf(_tokenId), winner, _tokenId, "");

    emit AuctionClaim(block.timestamp, msg.sender, _tokenId);
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721) {
    super._beforeTokenTransfer(from, to, tokenId);

    require(auctions[tokenId].seller == address(0), "In auction");
    require(!paused(), "Paused");
  }
}
