pragma solidity ^0.8.9;

import "./Counters.sol";

import "./NFTation.sol";

contract FixedPriceMarketPlaceStorage {

    

    // +STORAGE -------------------------------------------------
    Counters.Counter internal _itemIds;
    Counters.Counter internal _itemsSold;
    
    NFTation internal NFTationContract;
    uint8 internal marketPlaceShare;

    mapping(uint256 => MarketItem) internal idToMarketItem;
    
    // -STORAGE -------------------------------------------------

    // +STRUCTS -------------------------------------------------
    struct MarketItem {
        uint itemId;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
        bool isActive;
    }
    // -STRUCTS -------------------------------------------------

    uint256[45] private __gap;
}