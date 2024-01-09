// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721Holder.sol";
import "./ERC1155Holder.sol";
import "./IERC721.sol";


//   $$$$$$$\  $$$$$$$$\ $$\       $$\        $$$$$$\  $$$$$$$\
//   $$  __$$\ $$  _____|$$ |      $$ |      $$  __$$\ $$  __$$\
//   $$ |  $$ |$$ |      $$ |      $$ |      $$ /  $$ |$$ |  $$ |
//   $$$$$$$  |$$$$$\    $$ |      $$ |      $$$$$$$$ |$$$$$$$  |
//   $$  ____/ $$  __|   $$ |      $$ |      $$  __$$ |$$  __$$<
//   $$ |      $$ |      $$ |      $$ |      $$ |  $$ |$$ |  $$ |
//   $$ |      $$$$$$$$\ $$$$$$$$\ $$$$$$$$\ $$ |  $$ |$$ |  $$ |
//   \__|      \________|\________|\________|\__|  \__|\__|  \__|
//
//  Pellar 2022


contract PellarNftAuction is ERC721Holder, ERC1155Holder, Ownable {
  struct AuctionItem {
    address owner;
    address contractId;
    uint256 tokenId;
    uint256 reservePrice;
    uint256 startAt;
    uint256 endAt;
    address highestBidder;
    uint256 highestBid;
    uint256 bidCount;
    uint256 blockNumber;
  }

  // variables
  uint256 public windowTime = 5 minutes;
  mapping(bytes32 => AuctionItem) public auctionItems;
  mapping(bytes32 => uint256) public latestPrice;
  mapping(bytes32 => bool) public auctionEntered;

  // events
  event ItemListed(address indexed _contractId, uint256 indexed _tokenId, address indexed _sender, uint256 _reservePrice, uint256 _startAt, uint256 _endAt);
  event ItemBidded(address indexed _contractId, uint256 indexed _tokenId, address _newBidder, uint256 _newAmount, address indexed _oldBidder, uint256 _oldAmount, uint256 _bidCount);
  event AuctionWinnerWithdrawals(address indexed _contractId, uint256 indexed _tokenId, address indexed _winner, uint256 _highestBid);

  /* User */
  // verified
  function bid(address _contractId, uint256 _tokenId) external payable nonReentrant(_contractId, _tokenId) {
    (bytes32 auctionId, ) = getAuctionAndBid(_contractId, _tokenId);
    AuctionItem storage auctionItem = auctionItems[auctionId];

    require(tx.origin == msg.sender, "Not allowed");
    require(block.timestamp >= auctionItem.startAt, "Auction inactive"); // require auction starts
    require(block.timestamp <= auctionItem.endAt, "Auction ended"); // require auction not ended
    require(auctionItem.owner != msg.sender && auctionItem.owner != address(0), "Not allowed"); // require not owner or not listed auction item
    require(msg.value > auctionItem.highestBid && msg.value > auctionItem.reservePrice, "Bid underpriced"); // require valid ether value

    address oldBidder = auctionItem.highestBidder;
    uint256 oldAmount = auctionItem.highestBid;

    if (oldBidder != address(0)) {
      // funds return for previous
      payable(oldBidder).transfer(oldAmount);
    }

    // update state
    auctionItem.highestBidder = msg.sender;
    auctionItem.highestBid = msg.value;
    auctionItem.bidCount++;

    latestPrice[auctionId] = msg.value;

    if (block.timestamp + windowTime >= auctionItem.endAt) {
      auctionItem.endAt += windowTime;
    }

    // event
    emit ItemBidded(_contractId, _tokenId, msg.sender, msg.value, oldBidder, oldAmount, auctionItem.bidCount);
  }

  // verified
  function withdrawProductWon(address _contractId, uint256 _tokenId) external {
    (bytes32 auctionId, ) = getAuctionAndBid(_contractId, _tokenId);
    AuctionItem memory auctionItem = auctionItems[auctionId];

    require(block.timestamp > auctionItem.endAt, "Auction active!"); // need auction to end
    require(msg.sender == auctionItem.highestBidder || msg.sender == owner(), "Winner only!"); // need winner

    address winner = auctionItem.highestBidder;
    auctionItem.highestBidder = address(0); // convert state to address 0
    IERC721(_contractId).transferFrom(address(this), winner, _tokenId);

    // event
    emit AuctionWinnerWithdrawals(_contractId, _tokenId, winner, auctionItem.highestBid);
  }

  /* Admin */
  function setWindowTime(uint256 _time) external onlyOwner {
    windowTime = _time;
  }

  // verified
  function createAuction(address _contractId, uint256 _tokenId, uint256 _reservePrice, uint256 _startAt, uint256 _endAt) external onlyOwner {
    (bytes32 auctionId, ) = getAuctionAndBid(_contractId, _tokenId);
    require(_endAt >= block.timestamp && _startAt < _endAt, "Input invalid");
    require(IERC721(_contractId).ownerOf(_tokenId) == msg.sender, "Not allowed"); // require owner
    require(latestPrice[auctionId] == 0, "Need withdraw"); // need withdraw first if bid this product again

    IERC721(_contractId).transferFrom(msg.sender, address(this), _tokenId);

    auctionItems[auctionId] = AuctionItem({
      owner: msg.sender,
      contractId: _contractId,
      tokenId: _tokenId,
      reservePrice: _reservePrice,
      startAt: _startAt,
      endAt: _endAt,
      highestBidder: address(0),
      highestBid: 0,
      bidCount: 0,
      blockNumber: block.number
    });

    // emit
    emit ItemListed(_contractId, _tokenId, msg.sender, _reservePrice, _startAt, _endAt);
  }

  // verified
  function withdraw(address _contractId, uint256 _tokenId) external onlyOwner {
    (bytes32 auctionId, ) = getAuctionAndBid(_contractId, _tokenId);
    AuctionItem storage auctionItem = auctionItems[auctionId];

    require(block.timestamp > auctionItem.endAt, "Auction active!");
    require(latestPrice[auctionId] > 0, "No bids!");

    uint256 amount = latestPrice[auctionId];
    latestPrice[auctionId] = 0; // non reentrancy security
    payable(msg.sender).transfer(amount);
  }

  // verified
  function withdrawFailedAuction(address _contractId, uint256 _tokenId) external onlyOwner {
    (bytes32 auctionId, ) = getAuctionAndBid(_contractId, _tokenId);
    AuctionItem memory auctionItem = auctionItems[auctionId];

    require(block.timestamp > auctionItem.endAt, "Auction active!");
    require(auctionItem.bidCount == 0, "Action has bids!");

    IERC721(_contractId).transferFrom(address(this), msg.sender, _tokenId);
  }

  /* View */
  function getAuctionAndBid(address _contractId, uint256 _tokenId) public view returns (bytes32 _auctionId, AuctionItem memory _auctionItem) {
    _auctionId = keccak256(abi.encodePacked(_contractId, _tokenId));
    _auctionItem = auctionItems[_auctionId];
  }

  /* Security */
  modifier nonReentrant(address _contractId, uint256 _tokenId) {
    (bytes32 auctionId, ) = getAuctionAndBid(_contractId, _tokenId);
    require(!auctionEntered[auctionId], "ReentrancyGuard: reentrant call");
    auctionEntered[auctionId] = true;

    _;
    auctionEntered[auctionId] = false;
  }
}
