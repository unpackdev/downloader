// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./ERC721URIStorage.sol";

import "./console.sol";

contract NFTMarket is ERC721URIStorage, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;

    address payable contractOwner;
    uint256 listingPercent = 7;
    uint256 royaltiesPercent = 10;
    uint256 minimalPrice = 0.00028 ether;

    constructor() ERC721("Birth", "BIRTH") {
        contractOwner = payable(msg.sender);
    }

    struct MarketItem {
        uint itemId;
        address payable seller;
        address payable owner;
        address payable creator;
        uint256 price;
        bool sale;
    }

    mapping(uint => MarketItem) private itemIdToMarketItem;

    modifier IsMarketItemOwner(uint256 itemId, bool needOwner) {
        bool isOwner = itemIdToMarketItem[itemId].owner == msg.sender;
        if(needOwner) {
            require(isOwner, 'You not owned this item!');
        } else {
            require(!isOwner, 'You owned this item!');
        }
        _;
    }

    modifier IsMarketItemExist(uint256 itemId) {
        bool isExist = _itemIds.current() != 0 && itemIdToMarketItem[itemId].itemId == itemId;
        require(isExist, "Could not find item!");
        _;
    }

    modifier IsMarketItemOnSale(uint256 itemId, bool needOnSale) {
        bool onSale = itemIdToMarketItem[itemId].sale;
        if(needOnSale) {
            require(onSale, "This item is not sale!");
        } else {
            require(!onSale, "This item on sale!");
        }
        _;
    }

    function getListingPercent() public view returns (uint256) {
        return listingPercent;
    }

    function marketItemUpdatePrice(
        uint itemId,
        uint256 price
    )
    IsMarketItemOwner(itemId, true)
    IsMarketItemExist(itemId)
    IsMarketItemOnSale(itemId, true)
    public nonReentrant {
        require(price >= minimalPrice, "The price should be more than the minimal price!");
        itemIdToMarketItem[itemId].price = price;
    }

    function marketItemUpToSale(
        uint itemId,
        uint256 price
    )
    IsMarketItemOwner(itemId, true)
    IsMarketItemExist(itemId)
    IsMarketItemOnSale(itemId, false)
    public payable nonReentrant {
        require(price >= minimalPrice, "The price should be more than the minimal price!");
        approve(address(this), itemId);
        IERC721(address(this)).transferFrom(msg.sender, address(this), itemId);

        itemIdToMarketItem[itemId].sale = true;
        itemIdToMarketItem[itemId].seller = payable(msg.sender);
        itemIdToMarketItem[itemId].price = price;
    }

    function marketItemRemoveFromSale(
        uint itemId
    )
    IsMarketItemOwner(itemId, true)
    IsMarketItemExist(itemId)
    IsMarketItemOnSale(itemId, true)
    public payable nonReentrant {
        IERC721(address(this)).transferFrom(address(this), msg.sender, itemId);
        itemIdToMarketItem[itemId].sale = false;
    }

    function marketItemCreate(
        string memory tokenURI
    ) public returns (uint) {
        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        _mint(msg.sender, itemId);
        _setTokenURI(itemId, tokenURI);
        itemIdToMarketItem[itemId] = MarketItem(
            itemId,
            payable(msg.sender),
            payable(msg.sender),
            payable(msg.sender),
            0,
            false
        );

        return itemId;
    }

    function marketItemBuy(
        uint256 itemId
    )
    IsMarketItemOwner(itemId, false)
    IsMarketItemExist(itemId)
    IsMarketItemOnSale(itemId, true)
    public payable nonReentrant {
        uint256 itemPrice = itemIdToMarketItem[itemId].price;
        require(msg.value == itemPrice, "Not enough money!");

        uint256 royalties = calculatePercent(itemPrice, royaltiesPercent);
        uint256 listingPrice = calculatePercent(itemPrice, listingPercent);

        payable(contractOwner).transfer(listingPrice);
        payable(itemIdToMarketItem[itemId].creator).transfer(royalties);
        itemIdToMarketItem[itemId].seller.transfer(msg.value - listingPrice - royalties);
        IERC721(address(this)).transferFrom(address(this), msg.sender, itemId);

        itemIdToMarketItem[itemId].owner = payable(msg.sender);
        itemIdToMarketItem[itemId].seller = payable(msg.sender);
        itemIdToMarketItem[itemId].sale = false;
    }

    function marketItems() public view returns (MarketItem[] memory) {
        uint itemCount = _itemIds.current();
        uint currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 0; i < itemCount; i++) {
            uint currentId =  i + 1;
            MarketItem storage currentItem = itemIdToMarketItem[currentId];
            items[currentIndex] = currentItem;
            currentIndex += 1;
        }
        return items;
    }

    function marketItemsByUser() public view returns (MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (itemIdToMarketItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (itemIdToMarketItem[i + 1].seller == msg.sender) {
                uint currentId = i + 1;
                MarketItem storage currentItem = itemIdToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function marketItemById(uint itemId)
    public view returns (
        address seller,
        address owner,
        address creator,
        uint256 price,
        bool sale
    ) {
        MarketItem memory item = itemIdToMarketItem[itemId];
        return (
        item.seller,
        item.owner,
        item.creator,
        item.price,
        item.sale
        );
    }

    function calculatePercent(uint amount, uint percent) public pure returns(uint) {
        return amount / 100 * percent;
    }
}