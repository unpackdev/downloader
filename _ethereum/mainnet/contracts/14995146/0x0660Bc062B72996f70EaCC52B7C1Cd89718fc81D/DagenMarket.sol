// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Counters.sol";
import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./ERC721Holder.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract DagenMarket is ReentrancyGuard, Ownable, Pausable, ERC1155Holder {
  using Counters for Counters.Counter;
  using SafeMath for uint256;

  string public constant REVERT_NFT_NOT_SENT = "Marketplace::NFT not sent";

  Counters.Counter private _itemIds;
  Counters.Counter private _itemsSold;
  address payable public beneficiary;

  constructor(uint256 _fee) {
    beneficiary = payable(_msgSender());
    fee = _fee;
  }

  struct MarketItem {
    uint256 itemId;
    address nftContract;
    uint256 tokenId;
    address payable creator;
    address payable nftOwner;
    uint256 price;
    uint256 leftAmount;
    uint256 amount;
    bool bid;
    bool sold;
  }

  mapping(uint256 => MarketItem) private idToMarketItem;

  event MarketItemLog(
    uint256 indexed itemId,
    address indexed nftContract,
    uint256 indexed tokenId,
    address creator,
    address nftOwner,
    uint256 price,
    uint256 amount,
    bool bid,
    bool sold
  );

  // Recover NFT tokens sent by accident
  event NFTRecovery(address indexed token, uint256 indexed tokenId);

  // ============ Fee ==================================================

  // 2.5% in basis points
  uint256 public fee = 250;
  uint256 public constant HUNDRED_PERCENT = 10_000;

  // send fee to return left
  /// @param totalPrice Total price payable for the trade(s).
  function _takeFee(uint256 totalPrice) internal virtual returns (uint256) {
    uint256 cut = (totalPrice * fee) / HUNDRED_PERCENT;
    require(cut < totalPrice, "");
    payable(beneficiary).transfer(cut);
    uint256 left = totalPrice - cut;
    return left;
  }

  function changeFee(uint256 newFee) external onlyOwner {
    require(newFee < HUNDRED_PERCENT, "exceed");
    fee = newFee;
  }

  function changeBeneficiary(address _beneficiary) external onlyOwner {
    beneficiary = payable(_beneficiary);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  /**
   * @notice Create a sale order
   * @param nftContract: erc1155 contract
   * @param tokenId: token id
   * @param price: price
   * @param amount: amount
   */
  function createMarketItem(
    IERC1155 nftContract,
    uint256 tokenId,
    uint256 price,
    uint256 amount
  ) public payable nonReentrant whenNotPaused {
    require(price > 0, "Price must be greater than 0");

    _itemIds.increment();
    uint256 itemId = _itemIds.current();

    idToMarketItem[itemId] = MarketItem(
      itemId,
      address(nftContract),
      tokenId,
      payable(msg.sender),
      payable(address(this)),
      price,
      amount,
      amount,
      false,
      false
    );

    nftContract.safeTransferFrom(msg.sender, address(this), tokenId, amount, new bytes(0));

    emit MarketItemLog(
      itemId,
      address(nftContract),
      tokenId,
      msg.sender,
      address(this),
      price,
      amount,
      false,
      false
    );
  }

  /**
   * @notice Create a offer order
   * @param nftContract: erc1155 contract
   * @param tokenId: token id
   * @param price: price
   * @param amount: amount
   */
  function createBidMarketItem(
    IERC1155 nftContract,
    uint256 tokenId,
    uint256 price,
    uint256 amount
  ) public payable nonReentrant whenNotPaused {
    require(price > 0, "Price must be greater than 0");
    require(
      msg.value == price.mul(amount),
      "Incorrect value"
    );

    _itemIds.increment();
    uint256 itemId = _itemIds.current();

    idToMarketItem[itemId] = MarketItem(
      itemId,
      address(nftContract),
      tokenId,
      payable(msg.sender),
      payable(address(0)),
      price,
      amount,
      amount,
      true,
      false
    );

    emit MarketItemLog(
      itemId,
      address(nftContract),
      tokenId,
      msg.sender,
      address(0),
      price,
      amount,
      true,
      false
    );
  }

  /**
   * @notice Both sale and offer order can be remove, money or gen will send back depends on market item
   * @param nftContract: erc1155 contract
   * @param itemId: item id
   */
  function removeMarketItem(IERC1155 nftContract, uint256 itemId)
    public
    payable
    nonReentrant
    whenNotPaused
  {
    require(idToMarketItem[itemId].sold != true, "The order had finished");
    require(idToMarketItem[itemId].creator == payable(msg.sender), "Must be creator of item");
    if (idToMarketItem[itemId].bid) {
      payable(msg.sender).transfer(idToMarketItem[itemId].price.mul(idToMarketItem[itemId].amount));
    } else {
      idToMarketItem[itemId].nftOwner = payable(msg.sender);
      nftContract.safeTransferFrom(
        address(this),
        idToMarketItem[itemId].creator,
        idToMarketItem[itemId].tokenId,
        idToMarketItem[itemId].amount,
        new bytes(0)
      );
    }

    idToMarketItem[itemId].leftAmount = 0;
    idToMarketItem[itemId].sold = true;
    _itemsSold.increment();

    emit MarketItemLog(
      itemId,
      address(nftContract),
      idToMarketItem[itemId].tokenId,
      address(this),
      msg.sender,
      idToMarketItem[itemId].price,
      idToMarketItem[itemId].amount,
      idToMarketItem[itemId].bid,
      true
    );
  }

  /**
   * @notice Both sale and offer order can adjust price, if sale order just change the unit price of the gen, if offer order money cost will depends on unit price
   * @param itemId: item id
   * @param price: unit price
   */
  function adjustPrice(uint256 itemId, uint256 price) public payable nonReentrant whenNotPaused {
    // also means item exists
    require(idToMarketItem[itemId].creator == payable(msg.sender), "Must be creator of item");
    require(price != idToMarketItem[itemId].price, "should not same");

    uint256 amount = idToMarketItem[itemId].amount;
    if (idToMarketItem[itemId].bid) {
      if (price > idToMarketItem[itemId].price) {
        uint256 margin = price.mul(amount).sub(idToMarketItem[itemId].price.mul(amount));
        require(msg.value == margin, "Please submit correct price");
      } else {
        uint256 margin = idToMarketItem[itemId].price.mul(amount).sub(price.mul(amount));
        payable(msg.sender).transfer(margin);
      }
      idToMarketItem[itemId].price = price;
    } else {
      idToMarketItem[itemId].price = price;
    }

    emit MarketItemLog(
      itemId,
      idToMarketItem[itemId].nftContract,
      idToMarketItem[itemId].tokenId,
      idToMarketItem[itemId].creator,
      idToMarketItem[itemId].nftOwner,
      idToMarketItem[itemId].price,
      idToMarketItem[itemId].amount,
      idToMarketItem[itemId].bid,
      idToMarketItem[itemId].sold
    );
  }

  /**
   * @notice Deal the market item which has been saled, trader will get the gen
   * @param nftContract: erc1155 contract
   * @param itemId: item id
   * @param dealAmount: the amount to deal
   */
  function createMarketSale(
    IERC1155 nftContract,
    uint256 itemId,
    uint256 dealAmount
  ) public payable nonReentrant whenNotPaused {
    require(dealAmount > 0, "amount is 0");
    require(idToMarketItem[itemId].bid == false, "need sale order");
    require(idToMarketItem[itemId].sold != true, "order had finished");

    uint256 price = idToMarketItem[itemId].price;
    require(msg.value == price.mul(dealAmount), "invalid order value");

    uint256 tokenId = idToMarketItem[itemId].tokenId;
    uint256 leftAmount = idToMarketItem[itemId].leftAmount.sub(dealAmount);

    nftContract.safeTransferFrom(address(this), msg.sender, tokenId, dealAmount, new bytes(0));

    idToMarketItem[itemId].creator.transfer(_takeFee(msg.value));

    if (leftAmount == 0) {
      idToMarketItem[itemId].sold = true;
      _itemsSold.increment();
    }

    idToMarketItem[itemId].nftOwner = payable(msg.sender);
    idToMarketItem[itemId].leftAmount = leftAmount;

    emit MarketItemLog(
      itemId,
      address(nftContract),
      tokenId,
      address(this),
      msg.sender,
      price,
      dealAmount,
      false,
      leftAmount == 0
    );
  }

  /**
   * @notice Deal the market item which has been offered, trader will get the money
   * @param nftContract: erc1155 contract
   * @param itemId: item id
   * @param dealAmount: the amount to deal
   */
  function createMarketBuy(
    IERC1155 nftContract,
    uint256 itemId,
    uint256 dealAmount
  ) public payable nonReentrant whenNotPaused {
    require(dealAmount > 0, "amount is 0");
    require(idToMarketItem[itemId].bid == true, "need buy order");
    require(idToMarketItem[itemId].sold != true, "order had finished");

    uint256 price = idToMarketItem[itemId].price;
    uint256 tokenId = idToMarketItem[itemId].tokenId;

    uint256 leftAmount = idToMarketItem[itemId].leftAmount.sub(dealAmount);

    nftContract.safeTransferFrom(
      msg.sender,
      idToMarketItem[itemId].creator,
      tokenId,
      dealAmount,
      new bytes(0)
    );

    payable(msg.sender).transfer(_takeFee(dealAmount.mul(price)));

    if (leftAmount == 0) {
      idToMarketItem[itemId].sold = true;
      _itemsSold.increment();
    }

    idToMarketItem[itemId].nftOwner = idToMarketItem[itemId].creator;
    idToMarketItem[itemId].leftAmount = leftAmount;

    emit MarketItemLog(
      itemId,
      address(nftContract),
      tokenId,
      msg.sender,
      idToMarketItem[itemId].creator,
      price,
      dealAmount,
      true,
      leftAmount == 0
    );
  }

  /**
   * @notice View market items
   */
  function fetchMarketItems() public view returns (MarketItem[] memory) {
    uint256 itemCount = _itemIds.current();

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint256 i = 0; i < itemCount; i++) {
      MarketItem storage currentItem = idToMarketItem[i + 1];
      items[i] = currentItem;
    }
    return items;
  }

  /**
   * @notice View market items with pagination
   * @param cursor: cursor
   * @param size: size of the response
   */
  function fetchMarketItemsPaged(uint256 cursor, uint256 size)
    public
    view
    returns (MarketItem[] memory marketItems, uint256 total)
  {
    uint256 itemCount = _itemIds.current();
    MarketItem[] memory items = new MarketItem[](itemCount);

    uint256 length = size;

    if (length > itemCount - cursor) {
      length = itemCount - cursor;
    }

    marketItems = new MarketItem[](length);

    for (uint256 i = 0; i < length; i++) {
      MarketItem storage currentItem = idToMarketItem[cursor + 1];
      marketItems[i] = currentItem;
    }

    return (marketItems, items.length);
  }

  /**
   * @notice View on sale market items filter by nftContract and tokenId
   * @param nftContract: erc1155 contract
   * @param tokenId: token id
   */
  function fetchMarketItemsById(
    IERC1155 nftContract,
    uint256 tokenId,
    bool bid
  ) public view returns (MarketItem[] memory) {
    uint256 itemCount = _itemIds.current();

    // summarize count
    uint256 matchCount = 0;
    for (uint256 i = 0; i < itemCount; i++) {
      if (
        !idToMarketItem[i + 1].sold &&
        idToMarketItem[i + 1].nftContract == address(nftContract) &&
        idToMarketItem[i + 1].tokenId == tokenId &&
        idToMarketItem[i + 1].bid == bid
      ) {
        matchCount += 1;
      }
    }

    MarketItem[] memory items = new MarketItem[](matchCount);

    uint256 currentIndex = 0;
    for (uint256 i = 0; i < itemCount; i++) {
      if (
        !idToMarketItem[i + 1].sold &&
        idToMarketItem[i + 1].nftContract == address(nftContract) &&
        idToMarketItem[i + 1].tokenId == tokenId &&
        idToMarketItem[i + 1].bid == bid
      ) {
        uint256 currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }

    return items;
  }

  /**
   * @notice View on sale market items filter by nftContract and tokenId with pagination
   * @param nftContract: erc1155 contract
   * @param tokenId: token id
   * @param cursor: cursor
   * @param size: size of the response
   */
  function fetchMarketItemsByIdPaged(
    IERC1155 nftContract,
    uint256 tokenId,
    bool bid,
    uint256 cursor,
    uint256 size
  ) public view returns (MarketItem[] memory marketItems, uint256 total) {
    MarketItem[] memory items = fetchMarketItemsById(nftContract, tokenId, bid);

    uint256 length = size;

    if (length > items.length - cursor) {
      length = items.length - cursor;
    }

    marketItems = new MarketItem[](length);

    for (uint256 i = 0; i < length; i++) {
      marketItems[i] = items[cursor + i];
    }

    return (marketItems, items.length);
  }

  /**
   * @notice Allows the owner to recover NFTs sent to the contract by mistake
   * @param nftContract: NFT token address
   * @param tokenId: tokenId
   * @dev Callable by owner
   */
  function recoverNFT(
    IERC1155 nftContract,
    uint256 tokenId,
    uint256 amount
  ) external onlyOwner {
    nftContract.safeTransferFrom(address(this), address(msg.sender), tokenId, amount, new bytes(0));
    emit NFTRecovery(address(nftContract), tokenId);
  }
}
