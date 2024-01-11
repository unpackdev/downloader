//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC1155.sol";
import "./Interfaces.sol";


abstract contract Ownable {
    address public owner;
    constructor() {owner = msg.sender;}
    modifier onlyOwner {require(owner == msg.sender, "Not Owner!");
        _;}
    function transferOwnership(address new_) external onlyOwner {owner = new_;}
}

interface IOwnable {
    function owner() external view returns (address);
}

contract PawShop is Ownable {

    // Events

    event WLVendingItemAdded(address indexed operator_, WLVendingItem item_);
    event WLVendingItemModified(address indexed operator_, WLVendingItem before_, WLVendingItem after_);
    event WLVendingItemRemoved(address indexed operator_, WLVendingItem item_);
    event WLVendingItemPurchased(address indexed purchaser_, uint256 index_, WLVendingItem object_);


    IERC20 paw;
    IERC1155 tracker;
    IKumaVerse  kumaContract;

    constructor(address _pawContract, address _trackerContract, address _kumaverseContract) {
        paw = IERC20(_pawContract);
        tracker = IERC1155(_trackerContract);
        kumaContract = IKumaVerse(_kumaverseContract);
    }

    // holdersType -> 0 : anyone with paw, 1 : genesis and tracker holders, 2: tracker holders only
    // category -> 0 : WL spot, 1 : NFT
    struct WLVendingItem {
        string title;
        string imageUri;
        string projectUri;
        string description;

        uint32 amountAvailable;
        uint32 amountPurchased;

        uint32 startTime;
        uint32 endTime;

        uint256 price;

        uint128 holdersType;
        uint128 category;
    }

    modifier onlyAdmin() {
        require(shopAdmin[msg.sender], "You are not admin");
        _;
    }

    mapping(address => bool) public shopAdmin;
    // Database of Vending Items for each ERC20
    WLVendingItem[] public WLVendingItemsDb;

    // Database of Vending Items Purchasers for each ERC20
    mapping(uint256 => address[]) public contractToWLPurchasers;
    mapping(uint256 => mapping(address => bool)) public contractToWLPurchased;

    function setPermission(address _toUpdate, bool _isAdmin) external onlyOwner() {
        shopAdmin[_toUpdate] = _isAdmin;
    }

    function addItem(WLVendingItem memory WLVendingItem_) external onlyAdmin() {
        require(bytes(WLVendingItem_.title).length > 0,
            "You must specify a Title!");
        require(uint256(WLVendingItem_.endTime) > block.timestamp,
            "Already expired timestamp!");
        require(WLVendingItem_.endTime > WLVendingItem_.startTime,
            "endTime > startTime!");

        // Make sure that amountPurchased on adding is always 0
        WLVendingItem_.amountPurchased = 0;

        // Push the item to the database array
        WLVendingItemsDb.push(WLVendingItem_);

        emit WLVendingItemAdded(msg.sender, WLVendingItem_);
    }

    function editItem(uint256 index_, WLVendingItem memory WLVendingItem_) external onlyAdmin() {
        WLVendingItem memory _item = WLVendingItemsDb[index_];

        require(bytes(_item.title).length > 0,
            "This WLVendingItem does not exist!");
        require(bytes(WLVendingItem_.title).length > 0,
            "Title must not be empty!");

        require(WLVendingItem_.amountAvailable >= _item.amountPurchased,
            "Amount Available must be >= Amount Purchased!");

        WLVendingItemsDb[index_] = WLVendingItem_;

        emit WLVendingItemModified(msg.sender, _item, WLVendingItem_);
    }

    function deleteMostRecentWLVendingItem() external onlyAdmin() {
        uint256 _lastIndex = WLVendingItemsDb.length - 1;

        WLVendingItem memory _item = WLVendingItemsDb[_lastIndex];

        require(_item.amountPurchased == 0,
            "Cannot delete item with already bought goods!");

        WLVendingItemsDb.pop();
        emit WLVendingItemRemoved(msg.sender, _item);
    }
    //
    //    // Core Function of WL Vending (User) - ok
    //    // ~0xInuarashi @ 2022-04-08
    //    // As of Martian Market V2 this uses PriceController and TokenController values.
    //    // We wrap it all in a WLVendingObject item which aggregates WLVendingItem data
    function buyItem(uint256 index_) external {

        // Load the WLVendingObject to Memory
        WLVendingItem memory _object = getWLVendingObject(index_);

        // Check the necessary requirements to purchase
        require(bytes(_object.title).length > 0,
            "This WLVendingObject does not exist!");
        require(_object.amountAvailable > _object.amountPurchased,
            "No more WL remaining!");
        require(_object.startTime <= block.timestamp,
            "Not started yet!");
        require(_object.endTime >= block.timestamp,
            "Past deadline!");
        require(!contractToWLPurchased[index_][msg.sender],
            "Already purchased!");
        require(_object.price != 0,
            "Item does not have a set price!");
        require(paw.balanceOf(msg.sender) >= _object.price,
            "Not enough tokens!");
        require(canBuy(msg.sender, _object.holdersType), "You can't buy this");
        // Pay for the WL
        paw .transferFrom(msg.sender, address(this), _object.price);

        // Add the address into the WL List
        contractToWLPurchased[index_][msg.sender] = true;
        contractToWLPurchasers[index_].push(msg.sender);

        // Increment Amount Purchased
        WLVendingItemsDb[index_].amountPurchased++;

        emit WLVendingItemPurchased(msg.sender, index_, _object);
    }

    function canBuy(address _buyer, uint256 _holdersType) internal returns (bool) {

        if (_holdersType == 0) {
            return true;
        } else if (_holdersType == 1) {
            uint256 kumaBalance = kumaContract.balanceOf(_buyer);
            if (kumaBalance > 0) {
                return true;
            }
        } else if (_holdersType == 2) {
            uint256 trackerBalance = tracker.balanceOf(_buyer, 1);
            if (trackerBalance > 0) {
                return true;
            }
        }
        return false;
    }

    function getWLPurchasersOf(uint256 index_) public view
    returns (address[] memory) {
        return contractToWLPurchasers[index_];
    }

    function getWLVendingItemsLength() public view
    returns (uint256) {
        return WLVendingItemsDb.length;
    }

    function getWLVendingItemsAll() public view
    returns (WLVendingItem[] memory) {
        return WLVendingItemsDb;
    }

    function raw_getWLVendingItemsPaginated(uint256 start_,
        uint256 end_) public view returns (WLVendingItem[] memory) {
        uint256 _arrayLength = end_ - start_ + 1;
        WLVendingItem[] memory _items = new WLVendingItem[](_arrayLength);
        uint256 _index;

        for (uint256 i = 0; i < _arrayLength; i++) {
            _items[_index++] = WLVendingItemsDb[start_ + i];
        }

        return _items;
    }

    // Generally, this is the go-to read function for front-end interfaces.
    function getWLVendingObject(uint256 index_) public
    view returns (WLVendingItem memory) {
        WLVendingItem memory _item = WLVendingItemsDb[index_];
        return _item;
    }

    function getWLVendingObjectsPaginated(uint256 start_,
        uint256 end_) public view returns (WLVendingItem[] memory) {
        uint256 _arrayLength = end_ - start_ + 1;
        WLVendingItem[] memory _objects = new WLVendingItem[](_arrayLength);
        uint256 _index;

        for (uint256 i = 0; i < _arrayLength; i++) {

            uint256 _itemIndex = start_ + i;

            WLVendingItem memory _item = WLVendingItemsDb[_itemIndex];

            _objects[_index++] = _item;
        }

        return _objects;
    }
}
