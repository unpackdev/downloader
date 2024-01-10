// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

import "./ERC721.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./Counters.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";

import "./FixedPriceMarketPlaceStorage.sol";




contract FixedPriceMarketPlace is Initializable,
                                  OwnableUpgradeable,
                                  UUPSUpgradeable,PausableUpgradeable,ReentrancyGuardUpgradeable,FixedPriceMarketPlaceStorage {

    using Counters for Counters.Counter;

    // +EVENTS --------------------------------------------------
    event MarketItemDeleted(uint indexed itemId, uint256 tokenId);
    event MoneyTransferred(address from, address to, uint256 amount);
    event NFTTransferred(address from, address to, uint256 tokenId);
    event MarketItemCreated(
        uint indexed itemId,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        uint256 timestamp
        );
    event MarketItemSold(
        uint indexed itemId,
        uint256 indexed tokenId,
        address seller,
        address buyer
        );
    event MarketItemPriceChanged(uint256 itemId, uint256 newPrice);

    // -EVENTS --------------------------------------------------

    constructor() {}

    function initialize() initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }
    

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function initToken(address _NFTationContract,uint8 marketPlaceSharePercentage) public onlyOwner {
        NFTationContract = NFTation(_NFTationContract);
        marketPlaceShare = marketPlaceSharePercentage;
    }

    function changeMarketPlaceShare(uint8 _marketPlaceShare) external onlyOwner{
        marketPlaceShare = _marketPlaceShare;
    }

    function getMarketShareAndRoyalty(uint256 tokenId,uint256 price) private view 
    returns(uint256 marketShareAmount,uint256 royaltyAmount ,address  creator){
        bool isFirstSale = NFTationContract.checkFirstSale(tokenId);
        if(isFirstSale){
            marketShareAmount = (price *(marketPlaceShare+ (NFTationContract.getRoyaltyPercentage(tokenId))))/100;
            return (marketShareAmount, 0,address (0));
        }
        else{
             marketShareAmount = ((marketPlaceShare *price) /100);
            (creator, royaltyAmount) = NFTationContract.royaltyInfo(tokenId ,price);
            return (marketShareAmount, royaltyAmount,creator);
        }
    }

    function getMarketItemPrice(uint256 _marketItemId) public view returns(uint256) {
        return idToMarketItem[_marketItemId].price;
    }

    function createMarketItem(uint256 tokenId, uint256 price) external  whenNotPaused nonReentrant returns (uint256)   {
        require(price > 0, "price must be greater than 0");
        _itemIds.increment();
        uint itemId = _itemIds.current();
        idToMarketItem[itemId] = MarketItem(
            itemId,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false,
            true);

        //external call
        NFTationContract.transferFrom(msg.sender, address(this), tokenId);
        emit MarketItemCreated(itemId, tokenId, msg.sender, address(this), price, block.timestamp);
        return itemId;
    }

    function changeMarketItemPrice(uint256 _itemId, uint256 _newPrice) external whenNotPaused nonReentrant  {
        MarketItem storage _marketItem = idToMarketItem[_itemId];
        require(_marketItem.isActive, "Invalid market item");
        require(msg.sender == _marketItem.seller, "Only seller can change price");
        require(_newPrice > 0, "price must be greater than 0");
        _marketItem.price = _newPrice;
        emit MarketItemPriceChanged(_itemId, _newPrice);
    }

    function deleteMarketItem(uint256 _itemId) external whenNotPaused nonReentrant {
        MarketItem storage _marketItem = idToMarketItem[_itemId];
        require(_marketItem.sold == false, "Can't delete soled market item");
        require(msg.sender == _marketItem.seller, "Only owner can remove market item");
        uint256 tokenId = idToMarketItem[_itemId].tokenId;
        address seller = _marketItem.seller;
        delete idToMarketItem[_itemId];
        
        //external call
        NFTationContract.transferFrom(address(this),seller, tokenId);

        
        emit MarketItemDeleted(_itemId, idToMarketItem[_itemId].tokenId);
    }

    function createMarketSale(uint256 itemId) external payable whenNotPaused nonReentrant {
        MarketItem storage marketItem = idToMarketItem[itemId];
        uint price = marketItem.price;
        uint _tokenId = marketItem.tokenId;
        require(msg.value == price, "You should include the price of the item");
        require(msg.sender != marketItem.seller, 'seller can not buy its owned token');
        (uint256 marketPlaceShareAmount, uint256 royaltyAmount,address  tokenCreator) = getMarketShareAndRoyalty(_tokenId, price);
        marketItem.owner = payable(msg.sender);
        marketItem.sold = true;
        marketItem.isActive = false;
        _itemsSold.increment();

        //External call
         bool sent;
        (sent, ) = payable(owner()).call{value: marketPlaceShareAmount}("");
        require(sent);
        
        if(royaltyAmount > 0){
            (sent, ) = payable(tokenCreator).call{value: royaltyAmount}("") ;
            require(sent);
        }
        if(NFTationContract.checkFirstSale(_tokenId)){
            NFTationContract.disableFirstSale(_tokenId);
        }
        uint256 remaining = (price-(marketPlaceShareAmount))-(royaltyAmount);
        (sent, ) = payable(marketItem.seller).call{value: remaining}("") ;
        require(sent);
        NFTationContract.transferFrom(address(this), msg.sender, _tokenId);
        emit MoneyTransferred(msg.sender, marketItem.seller, remaining);
        emit NFTTransferred(address(this), msg.sender, _tokenId);
        emit MarketItemSold(itemId, _tokenId, marketItem.seller, msg.sender);
    }
}
