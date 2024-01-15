// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./Ownable.sol";
import "./PellarNFTEnumerable.sol";
import "./ERC721Holder.sol";
import "./ERC1155Holder.sol";

// HDKN 2022 = Pellar + DRP

contract HDKNToken is Ownable, PellarNFTEnumerable {
  struct SaleInfo {
    bool buyable;
    uint256 price;
  }

  struct AuctionInfo {
    bool active;
    bool bidding;
    uint64 startAt;
    uint64 endAt;
    uint64 windowTime;
    uint256 reservePrice;
    uint256 minimalBidGap;
    address highestBidder;
    uint256 highestBid;
  }

  struct TokenInfo {
    bool inited;
    SaleInfo saleInfo;
    AuctionInfo auctionInfo;
    string uri;
  }

  // vars
  mapping(uint16 => TokenInfo) public tokens;

  struct AuctionHistory {
    address bidder;
    uint256 amount;
    uint256 timestamp;
  }

  mapping(uint16 => AuctionHistory[]) public auctionHistories;

  mapping(uint16 => mapping(address => uint256)) public refunds;

  // events
  event TokenModified(uint256 indexed tokenId, TokenInfo tokenInfo);
  event ItemBidded(
    uint256 indexed tokenId,
    address newBidder,
    uint256 newAmount,
    address oldBidder,
    uint256 oldAmount,
    uint256 timestamp
  );

  constructor() ERC721("HDKN", "HDKN") {}

  /* View */
  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    require(_exists(_tokenId), "Non exists token");

    return tokens[uint16(_tokenId)].uri;
  }

  function getAuctionHistoriesLength(uint16 _tokenId) public view returns (uint256) {
    return auctionHistories[_tokenId].length;
  }

  function getAuctionHistories(
    uint16 _tokenId,
    uint256 _from,
    uint256 _to
  ) public view returns (AuctionHistory[] memory items) {
    uint256 size = auctionHistories[_tokenId].length;

    _to = size > _to ? _to : size;

    items = new AuctionHistory[](_to - _from);

    for (uint256 i = _from; i < _to; i++) {
      items[i - _from] = auctionHistories[_tokenId][i];
    }
  }

  /* User */
  function buyNow(uint16 _tokenId) external payable nonReentrant(_tokenId) onlyInited(_tokenId) {
    AuctionInfo storage auctionInfo = tokens[_tokenId].auctionInfo;
    SaleInfo memory saleInfo = tokens[_tokenId].saleInfo;
    require(tx.origin == msg.sender, "Not allowed");
    require(saleInfo.buyable, "Not active");
    require(msg.value >= saleInfo.price, "Underpriced");
    require(auctionInfo.highestBid <= ((saleInfo.price * 90) / 100), "Stopped");
    require(
      block.timestamp <= auctionInfo.endAt ||
        (block.timestamp > auctionInfo.endAt && //
          auctionInfo.highestBidder == address(0)),
      "Expired"
    );

    IERC721(address(this)).transferFrom(address(this), msg.sender, _tokenId);

    address oldBidder = auctionInfo.highestBidder;
    uint256 oldAmount = auctionInfo.highestBid;
    if (oldBidder != address(0)) {
      // funds return for previous
      (bool success, ) = oldBidder.call{ value: oldAmount }("");
      if (!success) {
        refunds[_tokenId][msg.sender] += oldAmount;
      }
    }

    // update state
    tokens[_tokenId].inited = false;
  }

  function bid(uint16 _tokenId) external payable nonReentrant(_tokenId) onlyInited(_tokenId) {
    AuctionInfo storage auctionInfo = tokens[_tokenId].auctionInfo;
    require(tx.origin == msg.sender, "Not allowed");
    require(auctionInfo.active, "Not active");
    require(block.timestamp >= auctionInfo.startAt, "Auction inactive");
    require(block.timestamp <= auctionInfo.endAt, "Auction ended");
    require(
      msg.value >= (auctionInfo.highestBid + auctionInfo.minimalBidGap) && //
        msg.value >= (auctionInfo.reservePrice + auctionInfo.minimalBidGap),
      "Bid underpriced"
    );

    address oldBidder = auctionInfo.highestBidder;
    uint256 oldAmount = auctionInfo.highestBid;
    if (oldBidder != address(0)) {
      // funds return for previous
      (bool success, ) = oldBidder.call{ value: oldAmount }("");
      if (!success) {
        refunds[_tokenId][msg.sender] += oldAmount;
      }
    }
    // update state
    auctionInfo.highestBidder = msg.sender;
    auctionInfo.highestBid = msg.value;

    // checkpoint
    auctionHistories[_tokenId].push(
      AuctionHistory({
        bidder: msg.sender, //
        amount: msg.value,
        timestamp: block.timestamp
      })
    );

    // window time
    if (block.timestamp + auctionInfo.windowTime >= auctionInfo.endAt) {
      auctionInfo.endAt += auctionInfo.windowTime;
    }

    // event
    emit ItemBidded(_tokenId, msg.sender, msg.value, oldBidder, oldAmount, block.timestamp);
  }

  function auctionWinnerWithdraw(uint16 _tokenId) external onlyInited(_tokenId) {
    AuctionInfo storage auctionInfo = tokens[_tokenId].auctionInfo;
    require(block.timestamp > auctionInfo.endAt, "Auction active");
    require(msg.sender == auctionInfo.highestBidder || msg.sender == owner(), "Winner only!");

    IERC721(address(this)).transferFrom(address(this), auctionInfo.highestBidder, _tokenId);

    // update state
    tokens[_tokenId].inited = false;
  }

  // failed case
  function bidderWithdraw(uint16 _tokenId) external {
    require(refunds[_tokenId][msg.sender] > 0, "Not allowed");

    uint256 funds = refunds[_tokenId][msg.sender];
    refunds[_tokenId][msg.sender] = 0;
    payable(msg.sender).transfer(funds);
  }

  /* Admin */
  // verified
  function createToken(
    uint16 _tokenId,
    bool _buyable,
    uint256 _price,
    bool _active,
    uint64 _startAt,
    uint64 _endAt,
    uint64 _windowTime,
    uint256 _reservePrice,
    uint256 _minimalBidGap,
    string memory _uri
  ) external onlyOwner {
    require(!_exists(_tokenId), "Already exists");
    require(!tokens[_tokenId].inited, "Already inited");
    require(block.timestamp < _endAt, "Invalid time");

    tokens[_tokenId].inited = true;

    tokens[_tokenId].saleInfo = SaleInfo({
      buyable: _buyable,
      price: _price
    });

    tokens[_tokenId].auctionInfo = AuctionInfo({
      active: _active,
      bidding: false,
      startAt: _startAt,
      endAt: _endAt,
      windowTime: _windowTime,
      reservePrice: _reservePrice,
      minimalBidGap: _minimalBidGap,
      highestBidder: address(0),
      highestBid: 0
    });

    tokens[_tokenId].uri = _uri;

    _mint(address(this), _tokenId);

    emit TokenModified(_tokenId, tokens[_tokenId]);
  }

  // verified
  function toggleTokenBuyable(uint16 _tokenId, bool _buyable) external onlyOwner onlyInited(_tokenId) {
    tokens[_tokenId].saleInfo.buyable = _buyable;

    emit TokenModified(_tokenId, tokens[_tokenId]);
  }

  // verified
  function setTokenPrice(uint16 _tokenId, uint256 _price) external onlyOwner onlyInited(_tokenId) {
    tokens[_tokenId].saleInfo.price = _price;

    emit TokenModified(_tokenId, tokens[_tokenId]);
  }

  // verified
  function toggleTokenBiddable(uint16 _tokenId, bool _biddable) external onlyOwner onlyInited(_tokenId) {
    tokens[_tokenId].auctionInfo.active = _biddable;

    emit TokenModified(_tokenId, tokens[_tokenId]);
  }

  // verified
  function setAuctionWindowTime(uint16 _tokenId, uint64 _windowTime) external onlyOwner onlyInited(_tokenId) {
    tokens[_tokenId].auctionInfo.windowTime = _windowTime;

    emit TokenModified(_tokenId, tokens[_tokenId]);
  }

  // verified
  function setAuctionTime(
    uint16 _tokenId,
    uint64 _startAt,
    uint64 _endAt
  ) external onlyOwner onlyInited(_tokenId) {
    require(block.timestamp < _endAt, "Invalid time");
    tokens[_tokenId].auctionInfo.startAt = _startAt;
    tokens[_tokenId].auctionInfo.endAt = _endAt;

    emit TokenModified(_tokenId, tokens[_tokenId]);
  }

  // verified
  function setAuctionBid(
    uint16 _tokenId,
    uint64 _reservePrice,
    uint64 _minimalBidGap
  ) external onlyOwner onlyInited(_tokenId) {
    tokens[_tokenId].auctionInfo.reservePrice = _reservePrice;
    tokens[_tokenId].auctionInfo.minimalBidGap = _minimalBidGap;

    emit TokenModified(_tokenId, tokens[_tokenId]);
  }

  // verified
  function setTokenURI(uint16 _tokenId, string memory _uri) external onlyOwner onlyInited(_tokenId) {
    tokens[_tokenId].uri = _uri;

    emit TokenModified(_tokenId, tokens[_tokenId]);
  }

  // verified
  function withdrawNFT(uint16[] memory _tokenIds) public onlyOwner {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      IERC721(address(this)).transferFrom(address(this), msg.sender, _tokenIds[i]);
    }
  }

  // verified
  function withdrawETH() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  /* Security */
  modifier onlyInited(uint16 _tokenId) {
    require(tokens[_tokenId].inited, "Not inited");
    _;
  }

  modifier nonReentrant(uint16 _tokenId) {
    AuctionInfo storage auctionInfo = tokens[_tokenId].auctionInfo;
    require(!auctionInfo.bidding, "Reentrancy Guard");
    auctionInfo.bidding = true;

    _;
    auctionInfo.bidding = false;
  }
}
