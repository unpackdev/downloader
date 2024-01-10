// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./SafeMath.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC1155.sol";
import "./IERC1155Receiver.sol";

import "./TnfpToken.sol";

/// @title TNFP Trader Contract
/// @author NFP Swap
/// @notice TNFP Trader Contract V1
contract TnfpTrader is ReentrancyGuard, IERC1155Receiver {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

    address payable owner;
    mapping(address => uint256) public _listedItemsForOwnerCount;

    constructor() {
        owner = payable(msg.sender);
    }

    struct MarketItem {
        uint itemId;
        address tNfpContract;
        uint256 tokenId;
        uint256 amount;
        address seller;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => MarketItem) private idToMarketItem;

    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed tNfpContract,
        uint256 indexed tokenId,
        uint256 amount,
        address seller,
        uint256 price,
        bool sold
    );

    event MarketItemSold(uint256 indexed itemId, uint256 amount, address buyer);

    /// @notice Mint a market item on behalf of an NFT owner and list on market place
    function mintMarketItem(
        string memory tokenURI,
        address nftAddress,
        uint256 nftTokenId,
        address tNfpContract,
        uint256 amount,
        uint256 price,
        uint productType
    ) public nonReentrant returns (uint256) {
        require(price > 0, "Price must be at least 1 wei");
        TnfpToken tokenToMint = TnfpToken(tNfpContract);
        uint256 tokenId = tokenToMint.mintProxy(
            tokenURI,
            nftAddress,
            nftTokenId,
            amount,
            productType,
            msg.sender
        );

        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        idToMarketItem[itemId] = MarketItem(
            itemId,
            tNfpContract,
            tokenId,
            amount,
            msg.sender,
            price,
            false
        );

        _listedItemsForOwnerCount[msg.sender] = _listedItemsForOwnerCount[
            msg.sender
        ].add(amount);

        emit MarketItemCreated(
            itemId,
            tNfpContract,
            tokenId,
            amount,
            msg.sender,
            price,
            false
        );
        return itemId;
    }

    /// @notice Transfers ownership of the item, as well as funds between parties
    function createMarketSale(
        address tNfpContract,
        uint256 itemId,
        uint256 amount
    ) public payable nonReentrant {
        uint price = idToMarketItem[itemId].price;
        uint tokenId = idToMarketItem[itemId].tokenId;
        require(msg.value == price.mul(amount), "Cannot purchase enough units");
        require(amount > 0, "Cannot purchase 0 units");
        require(
            amount <= idToMarketItem[itemId].amount,
            "Not enough units left to buy"
        );
        require(
            idToMarketItem[itemId].sold == false,
            "Item is not longer for sale"
        );

        uint256 fee = msg.value.mul(2).div(100);
        payable(owner).transfer(fee);
        uint256 salePrice = msg.value - fee;
        payable(idToMarketItem[itemId].seller).transfer(salePrice);
        IERC1155(tNfpContract).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId,
            amount,
            ""
        );

        _listedItemsForOwnerCount[
            idToMarketItem[itemId].seller
        ] = _listedItemsForOwnerCount[idToMarketItem[itemId].seller].sub(
            amount
        );
        idToMarketItem[itemId].amount = idToMarketItem[itemId].amount.sub(
            amount
        );
        if (idToMarketItem[itemId].amount == 0) {
            idToMarketItem[itemId].sold = true;
        }
        _itemsSold.increment();
        emit MarketItemSold(tokenId, amount, msg.sender);
    }

    /// @notice Fetch current market place items
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint itemCount = _itemIds.current();
        uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
        uint currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].sold == false) {
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /// @notice Fetch current market place items that were created by the msg.sender
    function fetchItemsCreated() public view returns (MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /// @notice onERC1155Received event for TNFP transfers
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /// @notice onERC1155BatchReceived event for TNFP transfers
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /// @notice Supports interface for TNFP transfers
    function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
        return
            interfaceID == 0x01ffc9a7 || // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
            interfaceID == 0x4e2312e0; // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
    }
}
