// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./IERC721Receiver.sol";
import "./ReentrancyGuard.sol";

contract RocketFactoryMarket is Ownable, IERC721Receiver, ReentrancyGuard {
    /*
        EVENTS
    */
    event ItemOnAuction(
        uint256 timestamp,
        uint256 indexed itemId,
        uint8 indexed itemType,
        Auction auction
    );
    event ItemClaimed(
        uint256 timestamp,
        uint256 indexed itemId,
        uint8 indexed itemType,
        Auction auction
    );
    event ItemBidded(
        uint256 timestamp,
        uint256 indexed itemId,
        uint8 indexed itemType,
        Auction auction
    );
    event ItemForSale(
        uint256 timestamp,
        uint256 indexed itemId,
        uint8 indexed itemType,
        Sale sale
    );
    event ItemSold(
        uint256 timestamp,
        uint256 indexed itemId,
        uint8 indexed itemType,
        address buyer,
        Sale sale
    );
    event ItemSaleCancelled(
        uint256 timestamp,
        uint256 indexed itemId,
        uint8 indexed itemType,
        Sale sale
    );
    event TradeCreated(uint256 timestamp, Trade trade);
    event TradeAccepted(uint256 timestamp, Trade trade);
    event TradeCancelled(uint256 timestamp, Trade trade);
    event TradeRejected(uint256 timestamp, Trade trade);
    event OfferCreated(
        uint256 timestamp,
        uint256 indexed itemId,
        uint8 indexed itemType,
        Offer offer
    );
    event OfferAccepted(
        uint256 timestamp,
        uint256 indexed itemId,
        uint8 indexed itemType,
        Offer offer
    );
    event OfferCancelled(
        uint256 timestamp,
        uint256 indexed itemId,
        uint8 indexed itemType,
        Offer offer
    );
    event OfferRejected(
        uint256 timestamp,
        uint256 indexed itemId,
        uint8 indexed itemType,
        Offer offer
    );

    /*
        STRUCTS
    */
    struct Sale {
        address seller;
        uint16 itemId;
        uint8 itemType;
        uint32 endTimestamp;
        address erc20;
        uint256 price;
    }

    struct Auction {
        address seller;
        uint16 itemId;
        uint8 itemType;
        uint32 endTimestamp;
        uint32 maxBidTimestamp;
        address erc20;
        address maxBidderAddress;
        uint256 startPrice;
        uint256 maxBidAmount;
    }

    struct Item {
        uint16 itemId;
        uint8 itemType;
    }

    struct Trade {
        address offerer;
        address offeree;
        Item[] offering;
        Item[] requesting;
    }

    struct Offer {
        address offerer;
        uint8 itemType;
        uint16 itemId;
        address offeree;
        address erc20;
        uint256 price;
    }

    mapping(uint8 => mapping(uint256 => Auction)) public itemsToAuction;
    mapping(uint8 => mapping(uint256 => Sale)) public itemsToSale;
    mapping(address => mapping(address => Trade)) public trades;
    mapping(uint8 => mapping(uint256 => mapping(address => Offer))) public offers;
    mapping(uint8 => address) itemTypeToTokenAddress;
    mapping(address => bool) allowedErc20;
    mapping(address => uint256) contractBalance;

    uint256 ownerCutPercentage = 1000;

    /* 
        MODIFIERS
    */

    modifier isNotBeingTransacted(uint16 _itemId, uint8 _itemType) {
        require(
            IERC721(itemTypeToTokenAddress[_itemType]).ownerOf(_itemId) != address(this),
            "The item is part of another transaction"
        );
        _;
    }

    modifier isOnSale(uint16 _itemId, uint8 _itemType) {
        require(
            itemsToSale[_itemType][_itemId].seller != address(0x0),
            "The item is not for sale"
        );
        _;
    }

    modifier isNotOnSale(uint16 _itemId, uint8 _itemType) {
        require(
            itemsToSale[_itemType][_itemId].seller == address(0x0),
            "The item is for sale"
        );
        _;
    }

    modifier isOnAuction(uint16 _itemId, uint8 _itemType) {
        require(
            itemsToAuction[_itemType][_itemId].seller != address(0x0),
            "The item is not on auction"
        );
        _;
    }

    modifier isNotOnAuction(uint16 _itemId, uint8 _itemType) {
        require(
            itemsToAuction[_itemType][_itemId].seller == address(0x0),
            "The item is on auction"
        );
        _;
    }

    modifier itemTypeExists(uint8 _itemType) {
        require(
            itemTypeToTokenAddress[_itemType] != address(0x0),
            "The item type does not exist"
        );
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /* 
        MANAGEMENT METHODS 
    */
    constructor() {
        allowedErc20[address(0x0)] = true;
    }

    function setItemTokenAddress(uint8 _itemType, address _itemTokenAddress)
        external
        onlyOwner
    {
        itemTypeToTokenAddress[_itemType] = _itemTokenAddress;
    }

    function setAllowedERC20(address _erc20, bool _allowed) external onlyOwner {
        allowedErc20[_erc20] = _allowed;
    }

    function withdraw(address _erc20) external onlyOwner {
        if (_erc20 == address(0x0)) {
            payable(msg.sender).transfer(contractBalance[_erc20]);
            contractBalance[_erc20] = 0;
        } else {
            IERC20(_erc20).transferFrom(address(this), msg.sender, contractBalance[_erc20]);
            contractBalance[_erc20] = 0;
        }
    }

    function returnItem(uint16 _itemId, uint8 _itemType, address _to) external onlyOwner {
        IERC721(itemTypeToTokenAddress[_itemType]).safeTransferFrom(address(this), _to, _itemId);
    }

    
    function deleteAuction(uint16 _itemId, uint8 _itemType) external onlyOwner {
        Auction memory auction = itemsToAuction[_itemType][_itemId];

        if (auction.maxBidderAddress != address(0x0)) {
            if (auction.erc20 == address(0x0)) {
                payable(auction.maxBidderAddress).transfer(
                    auction.maxBidAmount
                );
            } else {
                IERC20(auction.erc20).transfer(
                    auction.maxBidderAddress,
                    auction.maxBidAmount
                );
            }
        }

        IERC721(itemTypeToTokenAddress[_itemType]).safeTransferFrom(address(this), auction.seller, _itemId);
        
        delete itemsToAuction[_itemType][_itemId];
    }

    
    function deleteSale(uint16 _itemId, uint8 _itemType) external onlyOwner {
        Sale memory sale = itemsToSale[_itemType][_itemId];
        IERC721(itemTypeToTokenAddress[_itemType]).safeTransferFrom(address(this), sale.seller, _itemId);
        delete itemsToSale[_itemType][_itemId];
    }

    function checkBalance(address _erc20) external view onlyOwner returns (uint256) {
        return contractBalance[_erc20];
    }

    function setOwnerCut(uint16 _ownerCutPercentage) external onlyOwner {
        ownerCutPercentage = _ownerCutPercentage;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /* 
        SALES
    */
    function createSale(
        uint16 _itemId,
        uint8 _itemType,
        uint256 _price,
        uint32 _endTimestamp,
        address _erc20
    )
        external
        itemTypeExists(_itemType)
        isNotBeingTransacted(_itemId, _itemType)
    {
        IERC721 token = IERC721(itemTypeToTokenAddress[_itemType]);
        require(
            allowedErc20[_erc20] == true,
            "The specified ERC20 token is not allowed"
        );
        require(
            token.ownerOf(_itemId) == msg.sender,
            "Only the item owner can create an auction"
        );
        require(_price > 0, "Minimum price must be above 0");

        token.safeTransferFrom(msg.sender, address(this), _itemId);

        Sale storage sale = itemsToSale[_itemType][_itemId];

        sale.seller = msg.sender;
        sale.erc20 = _erc20;
        sale.itemId = _itemId;
        sale.itemType = _itemType;
        sale.price = _price;
        sale.endTimestamp = _endTimestamp;

        emit ItemForSale( uint32(block.timestamp % 2**32), _itemId, _itemType, sale);
    }

    function buy(
        uint16 _itemId,
        uint8 _itemType
    )
        external
        payable
        callerIsUser()
        itemTypeExists(_itemType)
        isOnSale(_itemId, _itemType)
    {
        Sale memory sale = itemsToSale[_itemType][_itemId];

        require(msg.sender != sale.seller, "Can't buy on your own sale"); 
        require( uint32(block.timestamp % 2**32) < sale.endTimestamp || sale.endTimestamp == 0, "Sale has finished already");

        uint256 sellerCut = sale.price;
        uint256 ownerCut = 0;

        if (sale.seller != owner()) {
            ownerCut = (sellerCut * ownerCutPercentage) / 10000;
            sellerCut = sellerCut - ownerCut;
        }

        if (sale.erc20 == address(0x0)) {
            require(
                msg.value >= sale.price,
                "Not enough Ether sent to complete the sale"
            );

            payable(sale.seller).transfer(sellerCut);
        } else {
            IERC20(sale.erc20).transferFrom(msg.sender, sale.seller, sellerCut);
            IERC20(sale.erc20).transferFrom(msg.sender, address(this), ownerCut);
        }

        contractBalance[sale.erc20] += ownerCut;

        delete itemsToSale[_itemType][_itemId];

        IERC721(itemTypeToTokenAddress[_itemType]).safeTransferFrom(
            address(this),
            msg.sender,
            _itemId
        );

        emit ItemSold( uint32(block.timestamp % 2**32), _itemId, _itemType, msg.sender, sale);
    }

    function cancelSale(uint16 _itemId, uint8 _itemType)
        external
        itemTypeExists(_itemType)
        isOnSale(_itemId, _itemType)
    {
        Sale memory sale = itemsToSale[_itemType][_itemId];
        require(
            sale.seller == msg.sender,
            "Only the creator can cancel the sale"
        );
        delete itemsToSale[_itemType][_itemId];
        IERC721(itemTypeToTokenAddress[_itemType]).safeTransferFrom(
            address(this),
            msg.sender,
            _itemId
        );
        emit ItemSaleCancelled( uint32(block.timestamp % 2**32), _itemId, _itemType, sale);
    }

    /*
       AUCTIONS
    */
    function createAuction(
        uint16 _itemId,
        uint8 _itemType,
        uint256 _startPrice,
        uint32 _endTimestamp,
        address _erc20
    )
        external
        itemTypeExists(_itemType)
        isNotBeingTransacted(_itemId, _itemType)
    {
        IERC721 token = IERC721(itemTypeToTokenAddress[_itemType]);
        require(
            token.ownerOf(_itemId) == msg.sender,
            "Only the item owner can create an auction"
        );
        require(
            allowedErc20[_erc20] == true,
            "The specified ERC20 token is not allowed"
        );

        token.safeTransferFrom(msg.sender, address(this), _itemId);

        Auction storage auction = itemsToAuction[_itemType][_itemId];
        auction.seller = msg.sender;
        auction.itemId = _itemId;
        auction.itemType = _itemType;
        auction.startPrice = _startPrice;
        auction.maxBidAmount = _startPrice;
        auction.endTimestamp = _endTimestamp;
        auction.erc20 = _erc20;

        emit ItemOnAuction( uint32(block.timestamp % 2**32), _itemId, _itemType, auction);
    }

    function placeBid(
        uint16 _itemId,
        uint8 _itemType,
        uint256 _bid
    )
        external
        payable
        callerIsUser()
        nonReentrant()
        isOnAuction(_itemId, _itemType)
    {
        Auction storage auction = itemsToAuction[_itemType][_itemId];

        require(msg.sender != auction.seller, "Cant bid on your own auction");
        require(
             uint32(block.timestamp % 2**32) <= auction.endTimestamp,
            "Auction has finished already"
        );

        uint256 bid = auction.erc20 == address(0x0) ? msg.value : _bid;

        if (auction.maxBidderAddress == address(0x0)) {
            require(
                bid >= auction.startPrice,
                "Not enough to top the current bid"
            );
        } else {
            require(
                bid > auction.maxBidAmount,
                "Not enough to top the current bid"
            );
        }


        if (auction.erc20 != address(0x0)) {
            IERC20(auction.erc20).transferFrom(msg.sender, address(this), bid);
        }

        if (auction.maxBidderAddress != address(0x0)) {
            if (auction.erc20 == address(0x0)) {
                payable(auction.maxBidderAddress).transfer(
                    auction.maxBidAmount
                );
            } else {
                IERC20(auction.erc20).transfer(
                    auction.maxBidderAddress,
                    auction.maxBidAmount
                );
            }
        }

        auction.maxBidderAddress = msg.sender;
        auction.maxBidAmount = bid;
        auction.maxBidTimestamp =  uint32(block.timestamp % 2**32);

        emit ItemBidded( uint32(block.timestamp % 2**32), _itemId, _itemType, auction);
    }

    function claim(uint16 _itemId, uint8 _itemType)
        external
        callerIsUser()
        isOnAuction(_itemId, _itemType)
    {
        Auction memory auction = itemsToAuction[_itemType][_itemId];
        require(
             uint32(block.timestamp % 2**32) > auction.endTimestamp,
            "Auction is not finished"
        );
        
        require(
            auction.maxBidderAddress == msg.sender || auction.seller == msg.sender, 
            "Only the winner or seller can claim"
        );

        delete itemsToAuction[_itemType][_itemId];

        if (auction.maxBidderAddress == address(0x0)) {
            IERC721(itemTypeToTokenAddress[_itemType]).safeTransferFrom(
                address(this),
                auction.seller,
                _itemId
            );

            return;
        }

        uint256 sellerCut = auction.maxBidAmount;
        uint256 ownerCut = 0;

        if (auction.seller != owner()) {
            ownerCut = (sellerCut * ownerCutPercentage) / 10000;
            sellerCut = sellerCut - ownerCut;
        }

        if (auction.erc20 != address(0x0)) {
            IERC20(auction.erc20).transfer(auction.seller, sellerCut);
        } else {
            payable(auction.seller).transfer(sellerCut);
        }

        contractBalance[auction.erc20] += ownerCut;

        IERC721(itemTypeToTokenAddress[_itemType]).safeTransferFrom(
            address(this),
            auction.maxBidderAddress,
            _itemId
        );
        emit ItemClaimed( uint32(block.timestamp % 2**32), _itemId, _itemType, auction);
    }

    /*
       TRADES
    */
    function proposeTrade(
        Item[] memory _offers,
        Item[] memory _requests,
        address _offeree
    ) external callerIsUser() {
        Trade storage trade = trades[_offeree][msg.sender];

        require(
            trade.offerer == address(0x0),
            "There is already a trade offering for the specified recipient"
        );

        for (uint256 i = 0; i < _offers.length; i++) {
            require(
                itemTypeToTokenAddress[_offers[i].itemType] != address(0x0),
                "The item type does not exist"
            );
            IERC721(itemTypeToTokenAddress[_offers[i].itemType])
                .safeTransferFrom(msg.sender, address(this), _offers[i].itemId);
            trade.offering.push(Item(_offers[i].itemId, _offers[i].itemType));
        }

        for (uint256 i = 0; i < _requests.length; i++) {
            require(
                itemTypeToTokenAddress[_requests[i].itemType] != address(0x0),
                "The item type does not exist"
            );
            require(
                IERC721(itemTypeToTokenAddress[_requests[i].itemType]).ownerOf(
                    _requests[i].itemId
                ) == _offeree,
                "A requested item does not belong to the specified wallet"
            );
            trade.requesting.push(
                Item(_requests[i].itemId, _requests[i].itemType)
            );
        }

        trade.offerer = msg.sender;
        trade.offeree = _offeree;

        emit TradeCreated( uint32(block.timestamp % 2**32), trade);
    }

    function acceptTrade(address _offerer) external callerIsUser() {
        Trade memory trade = trades[msg.sender][_offerer];

        require(
            trade.offerer != address(0x0),
            "No received trade offering found for the specified address"
        );

        delete trades[msg.sender][_offerer];

        for (uint256 i = 0; i < trade.offering.length; i++) {
            IERC721(itemTypeToTokenAddress[trade.offering[i].itemType])
                .safeTransferFrom(
                address(this),
                msg.sender,
                trade.offering[i].itemId
            );
        }

        for (uint256 i = 0; i < trade.requesting.length; i++) {
            delete itemsToSale[trade.requesting[i].itemType][trade.requesting[i].itemId];
            IERC721(itemTypeToTokenAddress[trade.requesting[i].itemType])
                .safeTransferFrom(
                msg.sender,
                trade.offerer,
                trade.requesting[i].itemId
            );
        }

        emit TradeAccepted( uint32(block.timestamp % 2**32), trade);
    }

    function cancelTrade(address _offeree) external callerIsUser() {
        Trade memory trade = trades[_offeree][msg.sender];

        require(
            trade.offerer != address(0x0),
            "No sent trade offering found for the specified address"
        );

        delete trades[_offeree][msg.sender];

        for (uint256 i = 0; i < trade.offering.length; i++) {
            IERC721(itemTypeToTokenAddress[trade.offering[i].itemType])
                .safeTransferFrom(
                address(this),
                trade.offerer,
                trade.offering[i].itemId
            );
        }

        emit TradeCancelled( uint32(block.timestamp % 2**32), trade);
    }

    function rejectTrade(address _offerer) external callerIsUser() {
        Trade memory trade = trades[msg.sender][_offerer];

        require(
            trade.offerer != address(0x0),
            "No received trade offering found for the specified address"
        );

        delete trades[msg.sender][_offerer];

        for (uint256 i = 0; i < trade.offering.length; i++) {
            IERC721(itemTypeToTokenAddress[trade.offering[i].itemType])
                .safeTransferFrom(
                address(this),
                trade.offerer,
                trade.offering[i].itemId
            );
        }

        emit TradeRejected( uint32(block.timestamp % 2**32), trade);
    }

    /*
       OFFERS
    */
    function makeAnOffer(
        uint16 _itemId,
        uint8 _itemType,
        uint256 _price,
        address _erc20
    ) external payable callerIsUser() nonReentrant() isNotBeingTransacted(_itemId, _itemType) {
        require(
            itemTypeToTokenAddress[_itemType] != address(0x0),
            "The item type does not exist"
        );

        address tokenOwner = IERC721(itemTypeToTokenAddress[_itemType]).ownerOf(_itemId);

        uint256 price = _erc20 == address(0x0) ? msg.value : _price;

        Offer storage offer = offers[_itemType][_itemId][msg.sender];

        require(offer.offerer == address(0x0), "There is already an offer made by you for this item.");

        offer.offerer = msg.sender;
        offer.offeree = tokenOwner;
        offer.price = price;
        offer.itemId = _itemId;
        offer.itemType = _itemType;
        offer.erc20 = _erc20;


        if (_erc20 != address(0x0)) {
            IERC20(_erc20).transferFrom(msg.sender, address(this), price);
        }

        emit OfferCreated( uint32(block.timestamp % 2**32), offer.itemId, offer.itemType, offer);
    }

    function cancelOffer(uint8 _itemType, uint16 _itemId)
        external
        callerIsUser()
        nonReentrant()
    {
        Offer memory offer = offers[_itemType][_itemId][msg.sender];
        delete offers[_itemType][_itemId][msg.sender];
         // NOTE: Should check offer exists before
        if (offer.erc20 != address(0x0)) {
            IERC20(offer.erc20).transfer(msg.sender, offer.price);
        } else {
            payable(msg.sender).transfer(offer.price);
        }

        emit OfferCancelled(
             uint32(block.timestamp % 2**32),
            offer.itemId,
            offer.itemType,
            offer
        );
    }

    function acceptOffer(address _offerer, uint8 _itemType, uint16 _itemId) external callerIsUser() isNotBeingTransacted(_itemId, _itemType) {
        Offer memory offer = offers[_itemType][_itemId][_offerer];
        delete offers[_itemType][_itemId][_offerer];
        
        IERC721(itemTypeToTokenAddress[offer.itemType]).safeTransferFrom(
            msg.sender,
            offer.offerer,
            offer.itemId
        );

        uint256 sellerCut = offer.price;
        uint256 ownerCut = 0;

        if (offer.offeree != owner()) {
            ownerCut = (sellerCut * ownerCutPercentage) / 10000;
            sellerCut = sellerCut - ownerCut;
        }

        if (offer.erc20 != address(0x0)) {
            IERC20(offer.erc20).transfer(msg.sender, sellerCut);
        } else {
            payable(msg.sender).transfer(sellerCut);
        }

        contractBalance[offer.erc20] += ownerCut;

        emit OfferAccepted(
             uint32(block.timestamp % 2**32),
            offer.itemId,
            offer.itemType,
            offer
        );
    }

    function rejectOffer(address _offerer, uint8 _itemType, uint16 _itemId)
        external
        callerIsUser()
        nonReentrant()
    {
        Offer memory offer = offers[_itemType][_itemId][_offerer];
        delete offers[_itemType][_itemId][_offerer];

        if (offer.erc20 != address(0x0)) {
            IERC20(offer.erc20).transfer(offer.offerer, offer.price);
        } else {
            payable(offer.offerer).transfer(offer.price);
        }

        emit OfferRejected(
             uint32(block.timestamp % 2**32),
            offer.itemId,
            offer.itemType,
            offer
        );
    }
}
