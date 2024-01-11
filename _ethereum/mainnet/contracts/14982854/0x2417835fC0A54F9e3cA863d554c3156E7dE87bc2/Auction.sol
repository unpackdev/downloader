// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Ownable.sol";
import "./ERC721Holder.sol";
import "./ERC1155Holder.sol";
import "./IERC721.sol";
import "./IERC1155.sol";


//   $$$$$$$\  $$$$$$$$\ $$\       $$\        $$$$$$\  $$$$$$$\
//   $$  __$$\ $$  _____|$$ |      $$ |      $$  __$$\ $$  __$$\
//   $$ |  $$ |$$ |      $$ |      $$ |      $$ /  $$ |$$ |  $$ |
//   $$$$$$$  |$$$$$\    $$ |      $$ |      $$$$$$$$ |$$$$$$$  |
//   $$  ____/ $$  __|   $$ |      $$ |      $$  __$$ |$$  __$$<
//   $$ |      $$ |      $$ |      $$ |      $$ |  $$ |$$ |  $$ |
//   $$ |      $$$$$$$$\ $$$$$$$$\ $$$$$$$$\ $$ |  $$ |$$ |  $$ |
//   \__|      \________|\________|\________|\__|  \__|\__|  \__|
//
//  Pellar + LightLink 2022


contract PellarNftAuction is ERC721Holder, ERC1155Holder, Ownable {
  struct AuctionItem {
    bool inited;
    ITEM_TYPE itemType;
    address highestBidder;
    uint256 highestBid;
    uint256 windowTime;
    uint256 minimalBidGap;
    uint256 reservePrice;
    uint256 startAt;
    uint256 endAt;
  }

  struct AuctionHistory {
    address bidder;
    uint256 amount;
    uint256 timestamp;
  }

  // constants
  enum ITEM_TYPE {
    _721,
    _1155
  }

  // variables
  mapping(bytes32 => AuctionItem) public auctionItems;

  mapping(bytes32 => AuctionHistory[]) public auctionHistories;

  mapping(bytes32 => mapping(address => uint256)) public refunds;

  mapping(bytes32 => bool) public auctionEntered;

  // events
  event ItemListed(address indexed _contractId, uint256 indexed _tokenId, uint256 _salt, uint256 _reservePrice, uint256 _startAt, uint256 _endAt);
  event ItemBidded(
    address indexed _contractId,
    uint256 indexed _tokenId,
    uint256 _salt,
    address _newBidder,
    uint256 _newAmount,
    address indexed _oldBidder,
    uint256 _oldAmount
  );
  event AuctionWinnerWithdrawals(address indexed _contractId, uint256 indexed _tokenId, uint256 _salt, address indexed _winner, uint256 _highestBid);

  /* User */
  function bid(
    address _contractId,
    uint256 _tokenId,
    uint256 _salt
  ) external payable nonReentrant(_contractId, _tokenId, _salt) {
    (bytes32 auctionId, ) = getAuctionAndBid(_contractId, _tokenId, _salt);
    AuctionItem storage auctionItem = auctionItems[auctionId];

    require(tx.origin == msg.sender, "Not allowed");
    require(auctionItem.inited, "Not allowed"); // require listed auction item
    require(block.timestamp >= auctionItem.startAt, "Auction inactive"); // require auction starts
    require(block.timestamp <= auctionItem.endAt, "Auction ended"); // require auction not ended
    require(
      msg.value >= (auctionItem.highestBid + auctionItem.minimalBidGap) && msg.value >= (auctionItem.reservePrice + auctionItem.minimalBidGap),
      "Bid underpriced"
    ); // require valid ether value

    address oldBidder = auctionItem.highestBidder;
    uint256 oldAmount = auctionItem.highestBid;

    if (oldBidder != address(0)) {
      // funds return for previous
      (bool success, ) = oldBidder.call{ value: oldAmount }("");
      if (!success) {
        refunds[auctionId][msg.sender] = oldAmount;
      }
    }

    // update state
    auctionItem.highestBidder = msg.sender;
    auctionItem.highestBid = msg.value;

    auctionHistories[auctionId].push(AuctionHistory({ bidder: msg.sender, amount: msg.value, timestamp: block.timestamp }));

    if (block.timestamp + auctionItem.windowTime >= auctionItem.endAt) {
      auctionItem.endAt += auctionItem.windowTime;
    }

    // event
    emit ItemBidded(_contractId, _tokenId, _salt, msg.sender, msg.value, oldBidder, oldAmount);
  }

  // verified
  function withdrawProductWon(
    address _contractId,
    uint256 _tokenId,
    uint256 _salt
  ) external {
    (bytes32 auctionId, ) = getAuctionAndBid(_contractId, _tokenId, _salt);
    AuctionItem storage auctionItem = auctionItems[auctionId];

    require(block.timestamp > auctionItem.endAt, "Auction active!"); // need auction to end
    require(msg.sender == auctionItem.highestBidder || msg.sender == owner(), "Winner only!"); // need winner

    address winner = auctionItem.highestBidder;
    auctionItem.highestBidder = address(0); // convert state to address 0

    if (auctionItem.itemType == ITEM_TYPE._721) {
      IERC721(_contractId).transferFrom(address(this), winner, _tokenId);
    } else {
      IERC1155(_contractId).safeTransferFrom(address(this), winner, _tokenId, 1, "");
    }

    // event
    emit AuctionWinnerWithdrawals(_contractId, _tokenId, _salt, winner, auctionItem.highestBid);
  }

  function bidderWithdraw(
    address _contractId,
    uint256 _tokenId,
    uint256 _salt
  ) external {
    (bytes32 auctionId, ) = getAuctionAndBid(_contractId, _tokenId, _salt);

    require(refunds[auctionId][msg.sender] > 0, "Not allowed");

    uint256 funds = refunds[auctionId][msg.sender];
    refunds[auctionId][msg.sender] = 0;
    payable(msg.sender).transfer(funds);
  }

  /* Admin */
  function setWindowTime(
    address _contractId,
    uint256 _tokenId,
    uint256 _salt,
    uint256 _time
  ) external onlyOwner {
    (bytes32 auctionId, ) = getAuctionAndBid(_contractId, _tokenId, _salt);
    AuctionItem storage auctionItem = auctionItems[auctionId];
    auctionItem.windowTime = _time;
  }

  function setMinimalBidGap(
    address _contractId,
    uint256 _tokenId,
    uint256 _salt,
    uint256 _bidGap
  ) external onlyOwner {
    (bytes32 auctionId, ) = getAuctionAndBid(_contractId, _tokenId, _salt);
    AuctionItem storage auctionItem = auctionItems[auctionId];
    auctionItem.minimalBidGap = _bidGap;
  }

  // verified
  function createAuction(
    ITEM_TYPE _type,
    address _contractId,
    uint256 _tokenId,
    uint256 _salt,
    uint256 _windowTime,
    uint256 _minimalBidGap,
    uint256 _reservePrice,
    uint256 _startAt,
    uint256 _endAt
  ) external onlyOwner {
    (bytes32 auctionId, AuctionItem memory auctionItem) = getAuctionAndBid(_contractId, _tokenId, _salt);
    require(!auctionItem.inited, "Already exists");
    require(_endAt >= block.timestamp && _startAt < _endAt, "Input invalid");

    if (_type == ITEM_TYPE._721) {
      IERC721(_contractId).transferFrom(msg.sender, address(this), _tokenId);
    } else {
      IERC1155(_contractId).safeTransferFrom(msg.sender, address(this), _tokenId, 1, "");
    }

    auctionItems[auctionId] = AuctionItem({
      inited: true,
      itemType: _type,
      highestBidder: address(0),
      highestBid: 0,
      windowTime: _windowTime,
      minimalBidGap: _minimalBidGap,
      reservePrice: _reservePrice,
      startAt: _startAt,
      endAt: _endAt
    });

    // emit
    emit ItemListed(_contractId, _tokenId, _salt, _reservePrice, _startAt, _endAt);
  }

  // verified
  function withdraw(
    address _contractId,
    uint256 _tokenId,
    uint256 _salt
  ) external onlyOwner {
    (bytes32 auctionId, ) = getAuctionAndBid(_contractId, _tokenId, _salt);
    AuctionItem storage auctionItem = auctionItems[auctionId];

    require(auctionItem.inited, "Not allowed");
    require(block.timestamp > auctionItem.endAt, "Auction active!");
    require(auctionItem.highestBid > 0, "No bids!");

    uint256 amount = auctionItem.highestBid;
    auctionItem.highestBid = 0;
    payable(msg.sender).transfer(amount);
  }

  // verified
  function withdrawFailedAuction(
    address _contractId,
    uint256 _tokenId,
    uint256 _salt
  ) external onlyOwner {
    (bytes32 auctionId, ) = getAuctionAndBid(_contractId, _tokenId, _salt);
    AuctionItem memory auctionItem = auctionItems[auctionId];

    require(block.timestamp > auctionItem.endAt, "Auction active!");
    require(auctionHistories[auctionId].length == 0, "Action has bids!");

    if (auctionItem.itemType == ITEM_TYPE._721) {
      IERC721(_contractId).transferFrom(address(this), msg.sender, _tokenId);
    } else {
      IERC1155(_contractId).safeTransferFrom(address(this), msg.sender, _tokenId, 1, "");
    }
  }

  /* View */
  function getAuctionAndBid(
    address _contractId,
    uint256 _tokenId,
    uint256 _salt
  ) public view returns (bytes32 _auctionId, AuctionItem memory _auctionItem) {
    _auctionId = keccak256(abi.encodePacked(_contractId, _tokenId, _salt));
    _auctionItem = auctionItems[_auctionId];
  }

  function getAuctionHistories(
    address _contractId,
    uint256 _tokenId,
    uint256 _salt,
    uint256 _from,
    uint256 _to
  ) public view returns (bool hasNext, AuctionHistory[] memory histories) {
    (bytes32 auctionId, ) = getAuctionAndBid(_contractId, _tokenId, _salt);

    uint256 size = auctionHistories[auctionId].length;
    hasNext = size > _to;

    _to = size > _to ? _to : size;

    histories = new AuctionHistory[](_to - _from);

    for (uint256 i = _from; i < _to; i++) {
      histories[i - _from] = auctionHistories[auctionId][i];
    }
  }

  /* Security */
  modifier nonReentrant(
    address _contractId,
    uint256 _tokenId,
    uint256 _salt
  ) {
    (bytes32 auctionId, ) = getAuctionAndBid(_contractId, _tokenId, _salt);
    require(!auctionEntered[auctionId], "ReentrancyGuard: reentrant call");
    auctionEntered[auctionId] = true;

    _;
    auctionEntered[auctionId] = false;
  }
}
