// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Counters.sol";
import "./ERC721URIStorage.sol";
import "./ERC721.sol";

import "./console.sol";

contract NFTMarketplace is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    uint256 listingFee = 0.0003 ether;
    uint256 priceUpdateFee = 0 ether;
    uint256 itemDelistFee = 0 ether;
    uint256 itemRelistFee = 0 ether;
    // address payable public immutable feeClaimer;
    uint256 salesFee = 3;
    bool payMod = false;
    address payable owner;
    address payable mod;

    mapping(uint256 => MarketItem) private idToMarketItem;

    struct MarketItem {
        uint256 tokenId;
        address payable minter;
        address payable seller;
        address payable owner;
        uint256 price;
        uint256 salesPrice;
        bool sold;
        bool listed;
    }

    event MarketItemCreated(
        uint256 indexed tokenId,
        address minter,
        address seller,
        address owner,
        uint256 price,
        uint256 salesPrice,
        bool sold,
        bool listed
    );

    constructor() ERC721("Nile NFT Marketplace", "NNMP") {
        owner = payable(msg.sender);
        mod = payable(0x902459e85d836B411C7077d75b650964cB686dfA);
    }

    function transferOwnership(address _newOwner) public {
        require(msg.sender == owner);
        owner = payable(_newOwner);
    }

    // Mod Address
    function updateModMode(bool _payMod) public payable {
        require(mod == msg.sender, "Only Mod owner can change this setting");
        payMod = _payMod;
    }

    function updateModAddress(address _modAddress) public payable {
        require(mod == msg.sender, "Only Mod can change this setting");
        mod = payable(_modAddress);
    }

    // Listing Fee

    function getListingFee() public view returns (uint256) {
        return listingFee;
    }

    function updateListingFee(uint256 _listingFee) public payable {
        require(
            owner == msg.sender,
            "Only marketplace owner can update listing price."
        );
        listingFee = _listingFee;
    }

    // Update Fee
    function getPriceUpdateFee() public view returns (uint256) {
        return priceUpdateFee;
    }

    function updatePriceUpdateFee(uint256 _priceUpdateFee) public payable {
        require(
            owner == msg.sender,
            "Only marketplace owner can update listing price."
        );
        priceUpdateFee = _priceUpdateFee;
    }

    // DelistFee
    function getItemDelistFee() public view returns (uint256) {
        return itemDelistFee;
    }

    function updateItemDelistFee(uint256 fee) public payable {
        require(
            owner == msg.sender,
            "Only marketplace owner can update listing price."
        );
        itemDelistFee = fee;
    }

    // Relist Fee
    function getItemRelistFee() public view returns (uint256) {
        return itemRelistFee;
    }

    function updateItemRelistFee(uint256 fee) public payable {
        require(
            owner == msg.sender,
            "Only marketplace owner can update listing price."
        );
        itemRelistFee = fee;
    }

    // Sales Fee
    function getSalesFee() public view returns (uint256) {
        return salesFee;
    }

    function updateSalesFee(uint256 _salesFee) public payable {
        require(
            owner == msg.sender,
            "Only marketplace owner can update Sales Fee."
        );
        salesFee = _salesFee;
    }

    /* Mints a token and lists it in the marketplace */
    function createToken(string memory tokenURI, uint256 price)
        public
        payable
        returns (uint256)
    {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        createMarketItem(newTokenId, price);
        return newTokenId;
    }

    function createMarketItem(uint256 tokenId, uint256 price) private {
        require(price > 0, "Price must be at least 1 wei");
        require(msg.value == listingFee, "Price must be equal to listing fee");

        uint256 totalPrice = calcTotalPrice(price);

        idToMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(msg.sender),
            payable(address(this)),
            price,
            totalPrice,
            false,
            true
        );

        //Send fee to owner
        payable(owner).transfer(listingFee);

        // List NFT in marketplace
        _transfer(msg.sender, address(this), tokenId);
        emit MarketItemCreated(
            tokenId,
            msg.sender,
            msg.sender,
            address(this),
            price,
            totalPrice,
            false,
            true
        );
    }

    /* allows someone to resell a token they have purchased */
    function resellToken(uint256 tokenId, uint256 price) public payable {
        require(
            idToMarketItem[tokenId].owner == msg.sender,
            "Only item owner can perform this operation"
        );
        require(
            msg.value == listingFee,
            "Price must be equal to listing price"
        );

        uint256 totalPrice = calcTotalPrice(price);
        idToMarketItem[tokenId].sold = false;
        idToMarketItem[tokenId].price = price;
        idToMarketItem[tokenId].salesPrice = totalPrice;
        idToMarketItem[tokenId].seller = payable(msg.sender);
        idToMarketItem[tokenId].owner = payable(address(this));
        idToMarketItem[tokenId].listed = true;
        _itemsSold.decrement();

        // Pay owner listing fee
        payable(owner).transfer(listingFee);
        _transfer(msg.sender, address(this), tokenId);
    }

    function getTotalPrice(uint256 tokenId) public view returns (uint256) {
        return ((idToMarketItem[tokenId].price * (100 + salesFee)) / 100);
    }

    function calcTotalPrice(uint256 price) public view returns (uint256) {
        return ((price * (100 + salesFee)) / 100);
    }

    function fetchItembyId(uint256 tokenId)
        public
        view
        returns (MarketItem memory)
    {
        return idToMarketItem[tokenId];
    }

    /* Creates the sale of a marketplace item */
    /* Transfers ownership of the item, as well as funds between parties */
    function createMarketSale(uint256 tokenId) public payable {
        uint256 totalPrice = getTotalPrice(tokenId);
        address seller = idToMarketItem[tokenId].seller;
        uint256 salesPrice = idToMarketItem[tokenId].price;
        require(
            msg.value >= totalPrice,
            "Not enough ether to cover item price and market fee"
        );
        // uint256 _totalPrice = getTotalPrice(_itemId);
        idToMarketItem[tokenId].owner = payable(msg.sender);
        idToMarketItem[tokenId].sold = true;
        idToMarketItem[tokenId].listed = false;
        idToMarketItem[tokenId].seller = payable(address(0));
        _itemsSold.increment();
        _transfer(address(this), msg.sender, tokenId);
        payable(owner).transfer(totalPrice - salesPrice);
        payable(seller).transfer(salesPrice);
    }

    function delistItem(uint256 tokenId) public payable {
        require(
            idToMarketItem[tokenId].owner == msg.sender,
            "Only item owner can perform this operation"
        );
        idToMarketItem[tokenId].listed = false;
    }

    function updateItemPrice(uint256 tokenId, uint256 price) public payable {
        require(
            msg.value == priceUpdateFee,
            "Not enough ether to cover item price update fee"
        );
        require(
            idToMarketItem[tokenId].owner == msg.sender,
            "Only item owner can perform this operation"
        );
        uint256 totalPrice = calcTotalPrice(price);
        idToMarketItem[tokenId].price = price;
        idToMarketItem[tokenId].salesPrice = totalPrice;
        payable(owner).transfer(priceUpdateFee);
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
        // TBR
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

    function fetchItemsByAddress(address _address)
        public
        view
        returns (MarketItem[] memory)
    {
        uint256 totalItemCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == _address) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == _address) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
}
