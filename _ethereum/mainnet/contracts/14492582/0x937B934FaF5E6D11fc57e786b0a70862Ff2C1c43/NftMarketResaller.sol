// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";
import "./NftTokenHandler.sol";
import "./RoalityHandler.sol";
import "./NftMarket.sol";

contract NftMarketResaller is AccessControl {
  using SafeMath for uint256;
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  enum SellMethod { NOT_FOR_SELL, FIXED_PRICE, SELL_TO_HIGHEST_BIDDER, SELL_WITH_DECLINING_PRICE, ACCEPT_OFFER }
  enum SellState { NONE, ON_SALE, PAUSED, SOLD, FAILED, CANCELED }

  NftMarket market;
  uint256 public comission;
  uint256 public maxBookDuration;
  uint256 public minBookDuration;

  constructor(NftMarket mainMarket) {
    market = mainMarket;
    comission = 25; // 25 / 1000 = 2.5%
    maxBookDuration = 86400 * 30 * 6; // six month
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(ADMIN_ROLE, msg.sender);
  }
  
  struct Book {
    bytes32 bookId;
    address erc20Contract;
    address nftContract;
    uint256 tokenId;
    uint256 price; // dealed price
    uint256[] priceOptions;
    SellMethod method;
    SellState state; // 0: NONE, 2: ON_SALE, 3: PAUSED
    address seller;
    address buyer;
    uint256 payableAmount;
  }

  struct BookTiming {
    uint256 timestamp;
    uint256 beginTime;
    uint256 endTime;
  }

  struct BookSummary {
    uint256 topAmount;
    address topBidder;
  }

  struct BookShare {
    uint256 comission;
    uint256 roality;
  }

  struct Bid {
    bytes32 bookId;
    address buyer;
    uint256 price;
    uint256 timestamp;
  }

  mapping(bytes32 => Book) public books;
  mapping(bytes32 => BookTiming) public booktimes;
  mapping(bytes32 => BookSummary) public booksums;
  mapping(bytes32 => BookShare) public bookshares;
  mapping(bytes32 => Bid) public biddings;

  event Booked(
    bytes32 bookId,
    address erc20Contract,
    address indexed nftContract,
    uint256 tokenId,
    address seller, 
    SellMethod method,
    uint256[] priceOptions,
    uint256 beginTime,
    uint256 bookedTime,
    bytes32 indexed tokenIndex
  );

  event Bidded(
    bytes32 bookId, 
    address indexed nftContract,
    uint256 tokenId,
    address seller, 
    address buyer, 
    uint256 price,
    uint256 timestamp,
    bytes32 indexed tokenIndex
  );

  event Dealed(
    address erc20Contract,
    address indexed nftContract,
    uint256 tokenId,
    address seller, 
    address buyer, 
    SellMethod method,
    uint256 price,
    uint256 comission,
    uint256 roality,
    uint256 dealedTime,
    bytes32 referenceId,
    bytes32 indexed tokenIndex
  );

  event Failed(
    address indexed nftContract,
    uint256 tokenId,
    address seller, 
    address buyer, 
    SellMethod method,
    uint256 price,
    uint256 timestamp,
    bytes32 referenceId,
    bytes32 indexed tokenIndex
  );

  modifier isBiddable(bytes32 bookId) {
    require(books[bookId].state == SellState.ON_SALE, "Not on sale.");
    require(books[bookId].method == SellMethod.SELL_TO_HIGHEST_BIDDER, "This sale didn't accept bidding.");
    require(booktimes[bookId].beginTime <= block.timestamp, "Auction not start yet.");
    require(booktimes[bookId].endTime > block.timestamp, "Auction finished.");
    _;
  }

  modifier isBuyable(bytes32 bookId) {
    require(books[bookId].state == SellState.ON_SALE, "Not on sale.");
    require(
      books[bookId].method == SellMethod.FIXED_PRICE || 
      books[bookId].method == SellMethod.SELL_WITH_DECLINING_PRICE, 
      "Sale not allow direct purchase.");
    require(booktimes[bookId].beginTime <= block.timestamp, "This sale is not availble yet.");
    require(booktimes[bookId].endTime > block.timestamp, "This sale has expired.");
    _;
  }

  modifier isValidBook(bytes32 bookId) {
    _validateBook(bookId);
    _;
  }

  modifier onlySeller(bytes32 bookId) {
    require(books[bookId].seller == msg.sender, "Only seller may modify the sale");
    _;
  }

  function _validateBook(bytes32 bookId) private view {
    
    require(
      address(books[bookId].nftContract) != address(0), 
      "NFT Contract unavailable");

    require(
      market.isNftApproved(
        books[bookId].nftContract, 
        books[bookId].tokenId, 
        books[bookId].seller), 
      "Owner hasn't grant permission for sell");

    require(booktimes[bookId].endTime > booktimes[bookId].beginTime, 
      "Duration setting incorrect");
    
    if(books[bookId].method == SellMethod.FIXED_PRICE) {
      require(books[bookId].priceOptions.length == 1, "Price format incorrect.");
      require(books[bookId].priceOptions[0] > 0, "Price must greater than zero.");
    }

    if(books[bookId].method == SellMethod.SELL_TO_HIGHEST_BIDDER) {
      require(books[bookId].priceOptions.length == 2, "Price format incorrect.");
      require(books[bookId].priceOptions[1] >= books[bookId].priceOptions[0], "Reserve price must not less then starting price.");
    }

    if(books[bookId].method == SellMethod.SELL_WITH_DECLINING_PRICE) {
      require(books[bookId].priceOptions.length == 2, "Price format incorrect.");
      require(books[bookId].priceOptions[0] > books[bookId].priceOptions[1], "Ending price must less then starting price.");
    }
  }

  function index(address nftContract, uint256 tokenId) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(nftContract, tokenId));
  }

  // this index ensure each book won't repeat
  function bookIndex(address nftContract, uint256 tokenId, uint256 timestamp) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(nftContract, tokenId, timestamp));
  }

  function bidIndex(bytes32 bookId, uint256 beginTime, address buyer) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(bookId, beginTime, buyer));
  }

  function decliningPrice(
    uint256 beginTime,
    uint256 endTime,
    uint256 startingPrice,
    uint256 endingPrice,
    uint256 targetTime
  ) public pure returns (uint256) {
      return startingPrice.sub(
        targetTime.sub(beginTime)
        .mul(startingPrice.sub(endingPrice))
        .div(endTime.sub(beginTime)));
  }


  function book(
    address erc20Contract,
    address nftContract, 
    uint256 tokenId, 
    uint256 beginTime,
    uint256 endTime,
    SellMethod method, 
    uint256[] memory priceOptions 
    ) public payable returns (bytes32) {
    // todo: add list fee
    require(NftTokenHandler.isOwner(nftContract, tokenId, msg.sender), "Callee doesn't own this token");
    require(market.isNftApproved(nftContract, tokenId, msg.sender), "Not having approval of this token.");
    require(beginTime > block.timestamp.sub(3600), "Sell must not start 1 hour earilar than book time.");
    require(endTime > block.timestamp.add(minBookDuration), "Sell ending in less than 5 minute will be revert.");
    require(endTime.sub(beginTime) < maxBookDuration, "Exceed maximum selling duration.");

    bytes32 bookId = bookIndex(nftContract, tokenId, block.timestamp);
    
    books[bookId].bookId = bookId;
    books[bookId].erc20Contract = erc20Contract;
    books[bookId].nftContract = nftContract;
    books[bookId].tokenId = tokenId;
    books[bookId].priceOptions = priceOptions;
    books[bookId].method = method;
    books[bookId].state = SellState.ON_SALE;
    books[bookId].seller = msg.sender;
    booktimes[bookId].timestamp = block.timestamp;
    booktimes[bookId].beginTime = beginTime;
    booktimes[bookId].endTime = endTime;
    bookshares[bookId].comission = comission;
    bookshares[bookId].roality = RoalityHandler.roality(nftContract);
    
    _validateBook(bookId);

    emit Booked(
      books[bookId].bookId, 
      books[bookId].erc20Contract,
      books[bookId].nftContract,
      books[bookId].tokenId,
      books[bookId].seller,
      books[bookId].method,
      books[bookId].priceOptions,
      booktimes[bookId].beginTime,
      block.timestamp,
      index(
        books[bookId].nftContract, 
        books[bookId].tokenId)
      );

    return bookId;
  }

  function priceOf(bytes32 bookId) public view returns (uint256) {
    
    if(books[bookId].method == SellMethod.FIXED_PRICE) {
      return books[bookId].priceOptions[0];
    }

    if(books[bookId].method == SellMethod.SELL_WITH_DECLINING_PRICE) {
      return decliningPrice(
        booktimes[bookId].beginTime,
        booktimes[bookId].endTime,
        books[bookId].priceOptions[0],
        books[bookId].priceOptions[1],
        block.timestamp
      );
    }

    if(books[bookId].method == SellMethod.SELL_TO_HIGHEST_BIDDER) {
      return booksums[bookId].topAmount;
    }

    return 0;
  }

  function priceOptionsOf(bytes32 bookId) public view returns (uint256[] memory) {
    return books[bookId].priceOptions;
  }

  function pauseBook(bytes32 bookId) public onlySeller(bookId) {
    require(books[bookId].state == SellState.ON_SALE, "Sale not available.");
    books[bookId].state = SellState.PAUSED;
  }

  function resumeBook(bytes32 bookId, uint256 endTime) public onlySeller(bookId) {
    require(books[bookId].state == SellState.PAUSED, "Sale not paused.");
    books[bookId].state = SellState.ON_SALE;
    booktimes[bookId].endTime = endTime;
  }

  function _cancelBook(bytes32 bookId) private {
    require(
      books[bookId].state != SellState.SOLD &&
      books[bookId].state != SellState.FAILED &&
      books[bookId].state != SellState.CANCELED, 
      "Sale ended."
    );
    
    books[bookId].buyer = address(0);
    booktimes[bookId].endTime = block.timestamp;
    books[bookId].state = SellState.CANCELED;

    emit Failed(
      books[bookId].nftContract, 
      books[bookId].tokenId,
      books[bookId].seller, 
      books[bookId].buyer,
      books[bookId].method, 
      books[bookId].price,
      block.timestamp,
      bookId,
      index(
        books[bookId].nftContract, 
        books[bookId].tokenId)
    );
  }

  function forceCancelBook(bytes32 bookId) public onlyRole(ADMIN_ROLE) {
    _cancelBook(bookId);
  }

  function cancelBook(bytes32 bookId) public onlySeller(bookId) {
    _cancelBook(bookId);
  }

  function bid(bytes32 bookId, uint256 price) public payable isValidBook(bookId) isBiddable(bookId) returns (bytes32) {
    require(market.isMoneyApproved(IERC20(books[bookId].erc20Contract), msg.sender, price), "Allowance or balance not enough for this bid");
    require(price >= books[bookId].priceOptions[0], "Bid amount too low.");
    require(price > booksums[bookId].topAmount, "Given offer lower than top offer.");
    
    bytes32 bidId = bidIndex(bookId, booktimes[bookId].beginTime, msg.sender);
    
    biddings[bidId].bookId = bookId;
    biddings[bidId].buyer = msg.sender;
    biddings[bidId].price = price;
    biddings[bidId].timestamp = block.timestamp;

    if(biddings[bidId].price > booksums[bookId].topAmount) {
      booksums[bookId].topAmount = biddings[bidId].price;
      booksums[bookId].topBidder = biddings[bidId].buyer;
    }

    emit Bidded(
      bookId,
      books[bookId].nftContract,
      books[bookId].tokenId,
      books[bookId].seller,
      biddings[bidId].buyer,
      biddings[bidId].price,
      biddings[bidId].timestamp,
      index(
        books[bookId].nftContract, 
        books[bookId].tokenId)
    );

    return bidId;
  }

  function endBid(bytes32 bookId) public isValidBook(bookId) {
    require(
      books[bookId].state != SellState.SOLD &&
      books[bookId].state != SellState.FAILED &&
      books[bookId].state != SellState.CANCELED, 
      "Sale ended."
    );
    require(books[bookId].method == SellMethod.SELL_TO_HIGHEST_BIDDER, "Not an auction.");
    require(block.timestamp > booktimes[bookId].endTime, "Must end after auction finish.");

    uint256 topAmount = booksums[bookId].topAmount;
    address buyer = booksums[bookId].topBidder;
    
    books[bookId].price = topAmount;
    books[bookId].buyer = buyer;
    
    if(
      buyer == address(0) ||
      topAmount < books[bookId].priceOptions[1] || // low than reserved price
      market.isMoneyApproved(IERC20(books[bookId].erc20Contract), buyer, topAmount) == false ||
      IERC20(books[bookId].erc20Contract).balanceOf(buyer) < topAmount // buy money not enough
      ) {
        
      books[bookId].state = SellState.FAILED;

      emit Failed(
        books[bookId].nftContract, 
        books[bookId].tokenId,
        books[bookId].seller, 
        books[bookId].buyer,
        books[bookId].method, 
        books[bookId].price,
        block.timestamp,
        bookId,
        index(
          books[bookId].nftContract, 
          books[bookId].tokenId)
      );
      
      return;
    }

    _deal(bookId);

    books[bookId].state = SellState.SOLD;
  }

  function buy(bytes32 bookId) public 
    isValidBook(bookId) 
    isBuyable(bookId) 
    payable {

    uint256 priceNow = priceOf(bookId);

    if(books[bookId].erc20Contract == address(0)) {

      require(msg.value >= priceNow, "Incorrect payment value.");

      // return exchanges
      if(msg.value > priceNow) {
        payable(msg.sender).transfer(msg.value - priceNow);
      }
      
      books[bookId].payableAmount = priceNow;

    }

    books[bookId].price = priceNow;
    books[bookId].buyer = msg.sender;
    booktimes[bookId].endTime = block.timestamp;

    _deal(bookId);

    books[bookId].state = SellState.SOLD;
  }

  function _deal(bytes32 bookId) private {

    market.deal{value:books[bookId].payableAmount}(
      books[bookId].erc20Contract, 
      books[bookId].nftContract, 
      books[bookId].tokenId, 
      books[bookId].seller, 
      books[bookId].buyer, 
      books[bookId].price, 
      bookshares[bookId].comission, 
      bookshares[bookId].roality, 
      RoalityHandler.roalityAccount(books[bookId].nftContract),
      bookId
    );

    emit Dealed(
      books[bookId].erc20Contract,
      books[bookId].nftContract,
      books[bookId].tokenId,
      books[bookId].seller,
      books[bookId].buyer,
      books[bookId].method,
      books[bookId].price,
      bookshares[bookId].comission,
      bookshares[bookId].roality,
      booktimes[bookId].endTime,
      bookId,
      index(
        books[bookId].nftContract, 
        books[bookId].tokenId)
    );
  }

  function alterFormula(
    uint256 _comission,
    uint256 _maxBookDuration,
    uint256 _minBookDuration
  ) public onlyRole(ADMIN_ROLE) {
    comission = _comission;
    maxBookDuration = _maxBookDuration;
    minBookDuration = _minBookDuration;
  }
}