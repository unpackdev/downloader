// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC721.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Initializable.sol";
import "./Nft.sol";

// import "./console.sol";

contract MarketplaceV4 is Initializable, ReentrancyGuardUpgradeable {
  struct Item {
    uint256 itemId;
    address nftContract;
    uint256 tokenId;
    uint256 price;
    address payable creator;
    address payable gap01; //GAP: address payable seller;
    address payable gap02; //GAP: address payable owner;
    bool gap03; // GAP: bool sold;
    bool forSale; // OLD: bool sellable;
  }

  struct ItemData {
    Item item;
    address nftOwner;
    PercentageShare[] royaltyFeeShares;
    string tokenUri;
  }

  struct PercentageShare {
    address payable owner;
    uint8 percentage;
  }

  struct OwnershipMigration {
    uint256 itemId;
    address newOwner;
  }

  struct RoyaltyFeeSharesMigration {
    uint256 itemId;
    PercentageShare[] royaltyFeeShares;
  }

  //CONSTANTS (here?)
  uint8 constant MAX_ROYALTY_FEE_SHARES_LENGTH = 5;

  //OLD MEMORY SLOTS
  uint256 public brokerageFeePercentage;
  uint256 public itemCount;
  uint256 public gap01; //GAP: itemSoldCount;
  uint256 public gap02; //GAP: itemsDeletedCount;
  address payable public owner;

  mapping(uint256 => Item) public items; // WARNING: if the struct changes, this has not to be used anymore
  uint256 public royaltyFeePercentage;

  //NEW MEMORY SLOTS
  uint256 public listingFee;
  mapping(address => bool) public allowedNftContracts;
  mapping(address => bool) public creators;
  mapping(uint256 => mapping(uint8 => PercentageShare)) public royaltyFeeShares;

  //EVENTS
  event ItemCreated(uint256 itemId, address sender);
  event ItemSaleStatusUpdate(
    uint256 itemId,
    bool forSale,
    uint256 price,
    address sender
  );
  event ItemTransferred(
    uint256 itemId,
    address destination,
    uint256 price,
    address sender
  );

  // modifiers
  modifier onlyAllowedNftContracts(address _nftContract) {
    require(
      allowedNftContracts[_nftContract],
      "This nft contract is not allowed"
    );
    _;
  }
  modifier onlyCreators() {
    require(creators[msg.sender], "Only creators can do this operation");
    _;
  }
  modifier onlyExistingItem(uint256 _itemId) {
    require(
      _itemId >= 0 &&
        _itemId <= itemCount &&
        items[_itemId].creator != address(0),
      "The item doesn't exist"
    );
    _;
  }
  modifier onlyItemCreator(uint256 _itemId) {
    require(
      items[_itemId].creator == msg.sender,
      "Only the item creator can do this operation"
    );
    _;
  }
  modifier onlyItemsForSale(uint256 _itemId) {
    require(items[_itemId].forSale, "Only items for sale are allowed");
    _;
  }
  modifier onlyItemsOfAllowedNftContracts(uint256 _itemId) {
    require(
      allowedNftContracts[items[_itemId].nftContract],
      "This item's nft contract is not allowed"
    );
    _;
  }
  modifier onlyNftOwner(uint256 _itemId) {
    require(
      getItemOwner(_itemId) == msg.sender,
      "Only the owner of the nft can do this operation"
    );
    _;
  }
  modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can do this operation");
    _;
  }
  modifier notNftOwner(uint256 _itemId) {
    require(
      getItemOwner(_itemId) != msg.sender,
      "The owner of the nft cannot do this operation"
    );
    _;
  }

  // initialization
  function _initialize(
    uint256 _listingFee,
    uint8 _brokerageFeePercentage,
    uint8 _royaltyFeePercentage
  ) internal virtual {
    listingFee = _listingFee;
    brokerageFeePercentage = _brokerageFeePercentage;
    royaltyFeePercentage = _royaltyFeePercentage;
  }

  function _migrateOwnerships(
    OwnershipMigration[] calldata _ownershipMigrations
  ) internal virtual {
    for (uint256 i = 0; i < _ownershipMigrations.length; i++) {
      _transferToken(
        _ownershipMigrations[i].itemId,
        _ownershipMigrations[i].newOwner
      );
    }
  }

  function migrateOwnerships(
    OwnershipMigration[] calldata _ownershipMigrations
  ) external onlyOwner nonReentrant {
    _migrateOwnerships(_ownershipMigrations);
  }

  function _migrateRoyaltyFeeShares(
    RoyaltyFeeSharesMigration[] calldata _royaltyFeeSharesMigration
  ) internal virtual {
    for (uint256 i = 0; i < _royaltyFeeSharesMigration.length; i++) {
      for (
        uint8 j = 0;
        j < _royaltyFeeSharesMigration[i].royaltyFeeShares.length;
        j++
      ) {
        royaltyFeeShares[_royaltyFeeSharesMigration[i].itemId][
          j
        ] = _royaltyFeeSharesMigration[i].royaltyFeeShares[j];
      }

      // set the limiter
      royaltyFeeShares[_royaltyFeeSharesMigration[i].itemId][
        uint8(_royaltyFeeSharesMigration[i].royaltyFeeShares.length)
      ] = PercentageShare(payable(address(0)), 0);
    }
  }

  function migrateRoyaltyFeeShares(
    RoyaltyFeeSharesMigration[] calldata _royaltyFeeSharesMigration
  ) external onlyOwner nonReentrant {
    _migrateRoyaltyFeeShares(_royaltyFeeSharesMigration);
  }

  function reInitialize(
    uint256 _listingFee,
    uint8 _brokerageFeePercentage,
    uint8 _royaltyFeePercentage
  ) external onlyOwner nonReentrant {
    _initialize(_listingFee, _brokerageFeePercentage, _royaltyFeePercentage);
    itemCount++; // TODO: make this optional (add itemCountIncrease parameter)
  }

  function initialize(
    uint256 _listingFee,
    uint8 _brokerageFeePercentage,
    uint8 _royaltyFeePercentage
  ) public initializer {
    owner = payable(msg.sender);
    _initialize(_listingFee, _brokerageFeePercentage, _royaltyFeePercentage);
  }

  /*
  function setOwner(address _newOwner) external onlyOwner nonReentrant {
    owner = payable(_newOwner);
  }
  // */

  // views
  function getItemOwner(
    uint256 _itemId
  ) public view onlyExistingItem(_itemId) returns (address) {
    Item storage item = items[_itemId];
    return NFTV4(item.nftContract).ownerOf(item.tokenId);
  }

  function getItemRoyaltyFeeShares(
    uint256 _itemId
  ) public view onlyExistingItem(_itemId) returns (PercentageShare[] memory) {
    uint8 sharesCount = 0;
    while (sharesCount <= MAX_ROYALTY_FEE_SHARES_LENGTH) {
      PercentageShare storage currentShare = royaltyFeeShares[_itemId][
        sharesCount
      ];
      if (currentShare.owner == address(0)) {
        break;
      }

      sharesCount++;
    }

    PercentageShare[] memory result = new PercentageShare[](sharesCount);
    for (uint8 i = 0; i < sharesCount; i++) {
      result[i] = royaltyFeeShares[_itemId][i];
    }

    return result;
  }

  function getItems(
    uint256 offset,
    uint256 take
  ) public view returns (ItemData[] memory) {
    require(offset >= 0, "offset has to be >= 0");
    require(take >= 0, "take has to be >= 0");

    if (offset >= itemCount || take == 0) {
      return new ItemData[](0);
    }

    uint256 lowerBoundary = 1 + offset;
    uint256 upperBoundary = lowerBoundary + take;
    if (upperBoundary > itemCount) {
      upperBoundary = itemCount;
    }

    ItemData[] memory result = new ItemData[](upperBoundary - lowerBoundary);
    for (uint256 i = 0; lowerBoundary + i < upperBoundary; i++) {
      uint256 itemId = lowerBoundary + i;
      Item storage currentItem = items[itemId];

      string memory tokenUri = NFTV4(currentItem.nftContract).tokenURI(
        currentItem.tokenId
      );

      address nftOwner = NFTV4(currentItem.nftContract).ownerOf(
        currentItem.tokenId
      );

      PercentageShare[] memory _royaltyFeeShares = getItemRoyaltyFeeShares(
        itemId
      );

      result[i] = ItemData(currentItem, nftOwner, _royaltyFeeShares, tokenUri);
    }

    return result;
  }

  // fees
  function setListingFee(uint256 _listingFee) external onlyOwner nonReentrant {
    listingFee = _listingFee;
  }

  function setBrokerageFeePercentage(
    uint8 _brokerageFeePercentage
  ) external onlyOwner nonReentrant {
    brokerageFeePercentage = _brokerageFeePercentage;
  }

  function setRoyaltyFeePercentage(
    uint8 _royaltyFeePercentage
  ) external onlyOwner nonReentrant {
    royaltyFeePercentage = _royaltyFeePercentage;
  }

  // item creation
  function _mint(
    address _nftContract,
    string calldata _tokenUri
  ) internal virtual returns (uint256) {
    return NFTV4(_nftContract).mint(_tokenUri);
  }

  function _createItem(
    address _nftContract,
    string calldata _tokenUri,
    PercentageShare[] calldata _royaltyFeesShares
  ) internal virtual returns (uint256) {
    require(msg.value >= listingFee, "Not enough ETH to list your item");
    require(
      _royaltyFeesShares.length <= MAX_ROYALTY_FEE_SHARES_LENGTH,
      "too much shareholders"
    );

    uint256 tokenId = _mint(_nftContract, _tokenUri);

    if (_royaltyFeesShares.length == 0) {
      // if the caller didn't specify any royalty, set the default
      royaltyFeeShares[itemCount][0] = PercentageShare(
        payable(msg.sender),
        100
      );
    } else {
      // if the caller specified some royalty, save it
      uint8 totalPercentage = 0;
      for (uint8 i = 0; i < _royaltyFeesShares.length; i++) {
        require(
          _royaltyFeesShares[i].percentage > 0 &&
            _royaltyFeesShares[i].percentage <= 100,
          "Percentage has to be in the (0-100] range"
        );

        totalPercentage += _royaltyFeesShares[i].percentage;
        require(totalPercentage <= 100, "Total percentage cannot exceed 100");

        royaltyFeeShares[itemCount][i] = PercentageShare(
          _royaltyFeesShares[i].owner,
          _royaltyFeesShares[i].percentage
        );
      }
      require(totalPercentage == 100, "Total percentage has to be 100");
    }

    uint256 itemId = itemCount;
    items[itemCount] = Item(
      itemId, // itemId
      _nftContract, // nftContract
      tokenId, // tokenId
      0, // price
      payable(msg.sender), // creator
      payable(address(0)), // GAP: address payable seller;
      payable(address(0)), // GAP address payable owner
      false, // GAP: bool sold
      false // forSale
    );
    itemCount++;

    owner.transfer(listingFee);
    NFTV4(_nftContract).transferToken(msg.sender, tokenId);

    return itemId;
  }

  function createItem(
    address _nftContract,
    string calldata _tokenUri,
    PercentageShare[] calldata _royaltyFeesShares
  )
    external
    payable
    onlyAllowedNftContracts(_nftContract)
    onlyCreators
    nonReentrant
  {
    uint256 itemId = _createItem(_nftContract, _tokenUri, _royaltyFeesShares);
    emit ItemCreated(itemId, msg.sender);
  }

  function createAndSellItem(
    address _nftContract,
    string calldata _tokenUri,
    uint256 _price,
    PercentageShare[] calldata _royaltyFeesShares
  )
    external
    payable
    onlyAllowedNftContracts(_nftContract)
    onlyCreators
    nonReentrant
  {
    uint256 itemId = _createItem(_nftContract, _tokenUri, _royaltyFeesShares);

    _sellItem(itemId, _price);

    emit ItemCreated(itemId, msg.sender);
    emit ItemSaleStatusUpdate(itemId, true, _price, msg.sender);
  }

  function createAndTransferItem(
    address _nftContract,
    string calldata _tokenUri,
    address _destination,
    PercentageShare[] calldata _royaltyFeesShares
  )
    external
    payable
    onlyAllowedNftContracts(_nftContract)
    onlyCreators
    nonReentrant
  {
    uint256 itemId = _createItem(_nftContract, _tokenUri, _royaltyFeesShares);

    _transferItem(itemId, _destination);

    emit ItemCreated(itemId, msg.sender);
    emit ItemTransferred(itemId, _destination, 0, msg.sender);
  }

  // item purchase
  function _purchaseItem(uint256 _itemId) internal virtual {
    Item storage item = items[_itemId];
    uint256 itemPrice = item.price;
    require(msg.value >= itemPrice, "Not enough ETH to cover the item's price");

    address payable itemOwner = payable(getItemOwner(_itemId));

    uint256 brokerTotal = (itemPrice / 100) * brokerageFeePercentage;
    uint256 royaltiesTotal = (itemPrice / 100) * royaltyFeePercentage;
    uint256 sellerTotal = itemPrice - brokerTotal - royaltiesTotal;

    //pay the royalties
    uint8 i = 0;
    PercentageShare storage _royaltyFeeShare = royaltyFeeShares[_itemId][i];
    while (
      _royaltyFeeShare.owner != address(0) && i < MAX_ROYALTY_FEE_SHARES_LENGTH
    ) {
      uint256 _royaltyTotal = (royaltiesTotal / 100) *
        _royaltyFeeShare.percentage;

      if (_royaltyFeeShare.owner == itemOwner) {
        // it it's the seller
        // increase its amount
        sellerTotal += _royaltyTotal;
      } else if (_royaltyFeeShare.owner == owner) {
        // it it's the broker
        // increase its amount
        brokerTotal += _royaltyTotal;
      } else {
        // if it's somebody else
        // pay him
        payable(_royaltyFeeShare.owner).transfer(_royaltyTotal);
      }

      i++;
      _royaltyFeeShare = royaltyFeeShares[_itemId][i];
    }

    // pay the broker
    owner.transfer(brokerTotal);

    // pay the seller
    itemOwner.transfer(sellerTotal);

    // transfer the nft
    _transferItem(_itemId, msg.sender);
  }

  function purchaseItem(
    uint256 _itemId
  )
    external
    payable
    onlyExistingItem(_itemId)
    onlyItemsForSale(_itemId)
    onlyItemsOfAllowedNftContracts(_itemId)
    notNftOwner(_itemId)
    nonReentrant
  {
    Item storage item = items[_itemId];
    uint256 itemPrice = item.price;

    _purchaseItem(_itemId);

    emit ItemTransferred(_itemId, msg.sender, itemPrice, msg.sender);
  }

  // item sale
  function _resetSaleStatus(uint256 _itemId) internal virtual {
    items[_itemId].forSale = false;
    items[_itemId].price = 0;
  }

  function _sellItem(uint256 _itemId, uint256 _price) internal virtual {
    require(_price >= 0, "price has to be >= 0");

    items[_itemId].forSale = true;
    items[_itemId].price = _price;
  }

  function revokeSale(
    uint256 _itemId
  ) external onlyExistingItem(_itemId) onlyNftOwner(_itemId) nonReentrant {
    _resetSaleStatus(_itemId);

    emit ItemSaleStatusUpdate(_itemId, false, 0, msg.sender);
  }

  function sellItem(
    uint256 _itemId,
    uint256 _price
  )
    external
    onlyExistingItem(_itemId)
    onlyItemsOfAllowedNftContracts(_itemId)
    onlyNftOwner(_itemId)
    nonReentrant
  {
    _sellItem(_itemId, _price);

    emit ItemSaleStatusUpdate(_itemId, true, _price, msg.sender);
  }

  // item transfer
  function _transferToken(
    uint256 _itemId,
    address _destination
  ) internal virtual {
    Item storage item = items[_itemId];
    NFTV4(item.nftContract).transferToken(_destination, item.tokenId);
  }

  function _transferItem(
    uint256 _itemId,
    address _destination
  ) internal virtual {
    _resetSaleStatus(_itemId);
    _transferToken(_itemId, _destination);
  }

  function transferItem(
    uint256 _itemId,
    address _destination
  )
    external
    onlyExistingItem(_itemId)
    onlyItemsOfAllowedNftContracts(_itemId)
    onlyNftOwner(_itemId)
    nonReentrant
  {
    _transferItem(_itemId, _destination);

    emit ItemTransferred(_itemId, _destination, 0, msg.sender);
  }

  // allowed nft contracts
  function allowNftContracts(
    address[] calldata addressList
  ) external onlyOwner nonReentrant {
    for (uint i = 0; i < addressList.length; i++) {
      allowedNftContracts[addressList[i]] = true;
    }
  }

  function banNftContracts(
    address[] calldata addressList
  ) external onlyOwner nonReentrant {
    for (uint i = 0; i < addressList.length; i++) {
      delete allowedNftContracts[addressList[i]];
    }
  }

  // creators
  function addCreators(
    address[] calldata addressList
  ) external onlyOwner nonReentrant {
    for (uint i = 0; i < addressList.length; i++) {
      creators[addressList[i]] = true;
    }
  }

  function removeCreators(
    address[] calldata addressList
  ) external onlyOwner nonReentrant {
    for (uint i = 0; i < addressList.length; i++) {
      delete creators[addressList[i]];
    }
  }

  // contract account handling
  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function withdraw(address wallet) external payable onlyOwner nonReentrant {
    uint256 balance = address(this).balance;
    require(balance > 0, "No balance to withdraw");
    (bool success, ) = wallet.call{value: balance}("");
    require(success, "Failed to send to WALLET.");
  }
}
