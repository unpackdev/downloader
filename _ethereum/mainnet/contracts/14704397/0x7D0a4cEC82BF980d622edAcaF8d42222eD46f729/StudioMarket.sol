/**
 *Submitted for verification at Etherscan.io on 2022-05-03
 */

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./Counters.sol";
import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC721URIStorage.sol";

contract STUDIOMARKET is ReentrancyGuard, ERC721URIStorage, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;
  Counters.Counter private _itemsSold;

  ///listing percentage is multiplied by 10 to support dynamic percentage update
  /// @dev get atual percentage by dividing value with 10
  uint256 listingPercentage = 25;

  bool _takeFees = true;
  bool _tokenActive = false;

  mapping(uint256 => MarketItem) private idToMarketItem;

  struct MarketItem {
    uint256 tokenId;
    address payable seller;
    address payable owner;
    address payable creator;
    uint256 price;
    uint256 tokens;
    uint256 royalty;
    bool sold;
  }

  event MarketItemCreated(uint256 indexed tokenId, address seller, address owner, address creator, uint256 price, uint256 royalty, bool sold);
  event MarketItemListed(uint256 tokenId, address seller, uint256 price, uint256 tokens);
  event MarketItemRemoved(uint256 indexed tokenId);
  event TokenTransferred(address indexed previousOwner, address indexed newOwner, uint256 indexed tokenId);

  constructor() ERC721('XSTUDIO', 'TXS') {}

  /* Updates the listing price of the contract */
  function updateListingPrice(uint256 _listingPrice) public onlyOwner {
    //validate _listingPrice value
    require(_listingPrice <= 500, 'Value Overflow: Stated Value Is Above 50 percent');

    listingPercentage = _listingPrice;
  }

  /* Returns the listing price of the contract */
  function getListingPrice() public view returns (uint256) {
    return listingPercentage;
  }

  /**
   * @dev Private function because it simply calculates commission and pays out accordingly.
   * Inputs & other validation likely will come from somewhere else in the contract.
   *
   * Handles All the payments and fees distribution
   *
   * Note: Numbers are multiplied by 10 in order to calculate dynamic tradefee percentages and avert solidity fixed integer issues
   */

  function takeCommission(
    address seller,
    address creator,
    address platform,
    uint256 amountPaid,
    uint256 commissionPercentage,
    uint256 royaltyPercent
  ) private {
    //validate royalty value
    require(royaltyPercent <= 500, 'Value Overflow: Steted Value Is Above 50 percent');

    // divide by 1000 because commission percentage is expressed as a uint * 10
    uint256 royaltyFee = (amountPaid * royaltyPercent) / 1000;
    uint256 platformFee = (amountPaid * commissionPercentage) / 1000;

    amountPaid -= royaltyFee;
    amountPaid -= platformFee;

    payable(platform).transfer(platformFee);

    if (seller == creator) {
      payable(creator).transfer(royaltyFee + amountPaid);
    } else {
      payable(creator).transfer(royaltyFee);
      payable(seller).transfer(amountPaid);
    }
  }

  function takeTokenCommission(
    address seller,
    address creator,
    address platform,
    uint256 tokens,
    uint256 commissionPercentage,
    uint256 royaltyPercent,
    address tokenContract
  ) private {
    //validate royalty value
    require(royaltyPercent <= 500, 'Value Overflow: Steted Value Is Above 50 percent');

    // divide by 1000 because commission percentage is expressed as a uint * 10
    uint256 royaltyFee = (tokens * royaltyPercent) / 1000;
    uint256 platformFee = (tokens * commissionPercentage) / 1000;

    if (_takeFees == true) {
      tokens -= platformFee;
      IERC20(tokenContract).transferFrom(msg.sender, platform, platformFee);
    }

    tokens -= royaltyFee;

    //distribute tokens if takefees is true
    if (seller == creator) {
      IERC20(tokenContract).transferFrom(msg.sender, seller, tokens + royaltyFee);
    } else {
      IERC20(tokenContract).transferFrom(msg.sender, creator, royaltyFee);
      IERC20(tokenContract).transferFrom(msg.sender, seller, tokens);
    }
  }

  /* Creates the sale of a marketplace item */
  /* Transfers ownership of the item, as well as funds between parties */
  function mintTokenTXS(
    string memory tokenURI,
    address creator,
    uint256 price,
    uint256 tokens,
    uint256 royalty,
    address tokenContract
  ) public nonReentrant returns (uint256) {
    require(tokens <= IERC20(tokenContract).balanceOf(msg.sender), 'not enough  tokens');
    require(tokens > 0, 'Token Price Must Be Greater Than Zero');
    require(price > 0, 'Price must be at least 1 wei');

    _tokenIds.increment();
    uint256 newTokenId = _tokenIds.current();
    _mint(msg.sender, newTokenId);
    _setTokenURI(newTokenId, tokenURI);
    _itemsSold.increment();

    idToMarketItem[newTokenId] = MarketItem(newTokenId, payable(creator), payable(msg.sender), payable(creator), price, tokens, royalty, false);

    //finish transaction and transfer token
    takeTokenCommission(creator, creator, owner(), tokens, listingPercentage, royalty, tokenContract);

    emit MarketItemCreated(newTokenId, address(this), msg.sender, creator, price, royalty, false);

    return newTokenId;
  }

  /* Mints a token and lists it in the marketplace */
  function mintToken(
    string memory tokenURI,
    address creator,
    uint256 price,
    uint256 tokens,
    uint256 royalty
  ) public payable nonReentrant returns (uint256) {
    require(price > 0, 'Price must be at least 1 wei');
    require(msg.value == price, 'Please submit the asking price in order to complete the purchase');
    if (_tokenActive == true) {
      require(tokens > 0, 'Token Price Must Be Greater Than Zero');
    }
    _tokenIds.increment();
    uint256 newTokenId = _tokenIds.current();

    _mint(msg.sender, newTokenId);
    _setTokenURI(newTokenId, tokenURI);
    _itemsSold.increment();

    idToMarketItem[newTokenId] = MarketItem(newTokenId, payable(creator), payable(msg.sender), payable(creator), price, tokens, royalty, false);

    takeCommission(creator, creator, owner(), price, listingPercentage, royalty);

    emit MarketItemCreated(newTokenId, address(this), msg.sender, creator, price, royalty, false);

    return newTokenId;
  }

  /* Creates the sale of a marketplace item */
  /* Transfers ownership of the item, as well as funds between parties */
  function buyToken(uint256 tokenId) public payable nonReentrant {
    uint256 price = idToMarketItem[tokenId].price;
    uint256 royaltyFee = idToMarketItem[tokenId].royalty;
    address seller = idToMarketItem[tokenId].seller;
    address creator = idToMarketItem[tokenId].creator;

    require(msg.value == price, 'Please submit the asking price in order to complete the purchase');
    idToMarketItem[tokenId].owner = payable(msg.sender);
    idToMarketItem[tokenId].sold = true;
    idToMarketItem[tokenId].seller = payable(address(this));
    _itemsSold.increment();
    _transfer(address(this), msg.sender, tokenId);

    //finish transaction and pay respective parties

    takeCommission(seller, creator, owner(), price, listingPercentage, royaltyFee);

    //emit market sales event
    emit TokenTransferred(seller, msg.sender, tokenId);
  }

  /* allows someone to purchase a listed token */
  function buyTokenTXS(uint256 tokenId, address tokenContract) public nonReentrant {
    uint256 tokens = idToMarketItem[tokenId].tokens;
    address seller = idToMarketItem[tokenId].seller;
    address creator = idToMarketItem[tokenId].creator;

    uint256 royaltyFee = idToMarketItem[tokenId].royalty;
    require(tokens <= IERC20(tokenContract).balanceOf(msg.sender), 'not enough tokens');
    require(tokens > 0, 'token option is not active for this asset yet!');

    idToMarketItem[tokenId].sold = false;
    idToMarketItem[tokenId].owner = payable(msg.sender);
    idToMarketItem[tokenId].seller = payable(address(this));
    _itemsSold.increment();
    _transfer(address(this), msg.sender, tokenId);

    //finish transaction and transfer token
    takeTokenCommission(seller, creator, owner(), tokens, listingPercentage, royaltyFee, tokenContract);

    //emit market sales event
    emit TokenTransferred(seller, msg.sender, tokenId);
  }

  /* allows someone to resell a token they have purchased */
  function resellToken(
    uint256 tokenId,
    uint256 price,
    uint256 tokens
  ) public nonReentrant {
    require(idToMarketItem[tokenId].owner == msg.sender, 'Only item owner can perform this operation');
    require(price > 0, 'Price must be at least 1 wei');
    if (_tokenActive == true) {
      require(tokens > 0, 'Token Price Must Be Greater Than Zero');
    }

    idToMarketItem[tokenId].sold = false;
    idToMarketItem[tokenId].price = price;
    idToMarketItem[tokenId].tokens = tokens;
    idToMarketItem[tokenId].seller = payable(msg.sender);
    idToMarketItem[tokenId].owner = payable(address(this));
    _itemsSold.decrement();
    _transfer(msg.sender, address(this), tokenId);

    //emit market item add event
    emit MarketItemListed(tokenId, msg.sender, price, tokens);
  }

  // allows user to change the price of a listed token

  function changePrice(
    uint256 tokenId,
    uint256 _price,
    uint256 _tokens
  ) public {
    require(idToMarketItem[tokenId].seller == msg.sender, 'Only item owner can perform this operation');
    if (_tokenActive == true) {
      require(_tokens > 0, 'Token Price Must Be Greater Than Zero');
    }

    idToMarketItem[tokenId].price = _price;
    idToMarketItem[tokenId].tokens = _tokens;
  }

  /* allows someone to remove a token from the market */
  function delistItem(uint256 tokenId) public {
    require(idToMarketItem[tokenId].seller == msg.sender, 'Only item owner can perform this operation');
    idToMarketItem[tokenId].sold = false;
    idToMarketItem[tokenId].seller = payable(address(this));
    idToMarketItem[tokenId].owner = payable(msg.sender);
    _itemsSold.increment();
    _transfer(address(this), msg.sender, tokenId);

    //emit item removal event
    emit MarketItemRemoved(tokenId);
  }

  /* Returns all unsold market items */
  function fetchMarketItems() public view returns (MarketItem[] memory) {
    uint256 itemCount = _tokenIds.current();
    uint256 unsoldItemCount = _tokenIds.current() - _itemsSold.current();
    uint256 currentIndex = 0;

    MarketItem[] memory items = new MarketItem[](unsoldItemCount);
    for (uint256 i = 0; i < itemCount; i++) {
      if (idToMarketItem[i + 1].owner == address(this)) {
        uint256 currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  /* Returns only items that a user has purchased */
  function fetchMyNFTs() public view returns (MarketItem[] memory) {
    uint256 totalItemCount = _tokenIds.current();
    uint256 itemCount = 0;
    uint256 currentIndex = 0;

    for (uint256 i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].owner == msg.sender) {
        itemCount += 1;
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint256 i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].owner == msg.sender) {
        uint256 currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  /* Returns only items a user has listed */
  function fetchItemsListed() public view returns (MarketItem[] memory) {
    uint256 totalItemCount = _tokenIds.current();
    uint256 itemCount = 0;
    uint256 currentIndex = 0;

    for (uint256 i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].seller == msg.sender) {
        itemCount += 1;
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint256 i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].seller == msg.sender) {
        uint256 currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }
}
