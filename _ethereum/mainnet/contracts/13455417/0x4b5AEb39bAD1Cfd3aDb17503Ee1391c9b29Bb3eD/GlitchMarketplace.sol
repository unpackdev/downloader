//
//   _____ _          _____ _ _ _       _
//  |_   _| |_ ___   |   __| |_| |_ ___| |_ ___ ___
//    | | |   | -_|  |  |  | | |  _|  _|   | -_|_ -|
//    |_| |_|_|___|  |_____|_|_|_| |___|_|_|___|___|
//
//
// The Glitches
// A free to mint 5k PFP project, focused on diversity and inclusion. We are community oriented.
//
// Twitter: https://twitter.com/theglitches_
//
// Project by:      @daniel100eth
// Art by:          @maxwell_step
// Code by:         @altcryp
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./IERC721.sol";


contract GlitchMarketplace is Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private orderIds;
    Counters.Counter private tradeIds;

    bool public active = true;
    uint256 royalty = 5;
    address royaltyAddress;

    IERC721 Glitch;

    struct Order {
        address seller;
        address buyer;
        uint256 tokenId;
        uint256 price;
        bool isActive;
    }

    struct Trade {
        address seller;
        address buyer;
        uint256 tokenId_1;
        uint256 tokenId_2;
        bool isActive;
        string memo;
        uint256 responses;
    }

    struct Status {
        uint256 forSale;
        uint256 forTrade;
        uint256 forTradeResponse;
    }

    uint256 public activeOrders;
    mapping (uint256 => Order) public Orders;

    uint256 public activeTrades;
    mapping (uint256 => Trade) public Trades;
    mapping (uint256 => mapping(uint256 => uint256)) public TradeResponses;  // maps trade id to token ids

    event TradeEvent(uint256 tradeId, uint256 tokenId_1, uint256 tokenId_2, address seller, address buyer);
    event TradeListedEvent(uint256 tradeId, uint256 tokenId_1, string memo, address seller);
    event SaleEvent(uint256 orderId, uint256 tokenId, uint256 amount, address seller, address buyer);
    event SaleListedEvent(uint256 orderId, uint256 tokenId, uint256 amount, address seller);

    // Constructor
    constructor(address glitchAddress, address _royaltyAddress) {
        Glitch = IERC721(glitchAddress);
        royaltyAddress = _royaltyAddress;
    }

    // List
    function list(uint256 tokenId, uint256 price) public {
        require(active, "Transfers are not active.");
        require(Glitch.ownerOf(tokenId) == msg.sender, "You must be owner to list.");
        require(Glitch.isApprovedForAll(msg.sender, address(this)), "You must approve tokens first.");
        Status memory status = getGlitchStatus(tokenId);
        require(status.forSale == 0, "Glitch is already for sale.");
        require(status.forTrade == 0, "Glitch is already for trade.");
        require(status.forTradeResponse == 0, "Glitch is already for trade response.");

        orderIds.increment();
        Orders[orderIds.current()] = Order(msg.sender, address(0), tokenId, price, true);
        activeOrders++;

        emit SaleListedEvent(orderIds.current(), tokenId, price, msg.sender);
    }

    function changePrice(uint256 tokenId, uint256 price) public {
        require(Glitch.ownerOf(tokenId) == msg.sender, "You must be owner to change price.");
        Status memory status = getGlitchStatus(tokenId);
        require(status.forSale > 0, "Glitch is not for sale.");

        Orders[status.forSale].price = price;
    }

    // Buy
    function buy(uint256 orderId) public payable {
        require(active, "Transfers are not active.");
        require(Orders[orderId].isActive, "Order is not active.");
        require(msg.value == Orders[orderId].price, "Price is not correct.");

        Order memory order = Orders[orderId];
        order.buyer = msg.sender;
        order.isActive = false;
        Orders[orderId] = order;
        activeOrders--;

        uint256 royaltyAmount = order.price.mul(royalty).div(100);

        Glitch.safeTransferFrom(order.seller, order.buyer, order.tokenId);
        payable(order.seller).transfer(order.price.sub(royaltyAmount));

        emit SaleEvent(orderId, order.tokenId, order.price, order.seller, order.buyer);
    }

    // TradeSeek
    function tradeSeek(uint256 tokenId, string memory memo) public {
        require(active, "Transfers are not active.");
        require(Glitch.ownerOf(tokenId) == msg.sender, "You must be owner to trade.");
        require(Glitch.isApprovedForAll(msg.sender, address(this)), "You must approve tokens first.");

        Status memory status = getGlitchStatus(tokenId);
        require(status.forSale == 0, "Glitch is already for sale.");
        require(status.forTrade == 0, "Glitch is already for trade.");
        require(status.forTradeResponse == 0, "Glitch is already for trade response.");

        tradeIds.increment();
        Trades[tradeIds.current()] = Trade(msg.sender, address(0), tokenId, 0, true, memo, 0);
        activeTrades++;

        emit TradeListedEvent(tradeIds.current(), tokenId, memo, msg.sender);
    }

    // TradeResponse
    function tradeResponse(uint256 tradeId, uint256 tokenId) public {
        require(active, "Transfers are not active.");
        require(Glitch.ownerOf(tokenId) == msg.sender, "You must be owner to trade.");
        require(Glitch.isApprovedForAll(msg.sender, address(this)), "You must approve tokens first.");
        require(Trades[tradeId].isActive, "Trade is no longer active.");

        Status memory status = getGlitchStatus(tokenId);
        require(status.forSale == 0, "Glitch is already for sale.");
        require(status.forTrade == 0, "Glitch is already for trade.");
        require(status.forTradeResponse == 0, "Glitch is already for trade response.");

        Trades[tradeId].responses++;
        TradeResponses[tradeId][Trades[tradeId].responses] = tokenId;
    }

    // TradeAccept
    function tradeAccept(uint256 tradeId, uint256 responseId) public {
        require(active, "Transfers are not active.");
        require(Trades[tradeId].seller == msg.sender, "You are not the seller.");
        require(Glitch.ownerOf(Trades[tradeId].tokenId_1) == msg.sender, "You must be owner to trade.");
        require(Trades[tradeId].isActive, "Trade is no longer active.");

        uint256 tradeTokenId = TradeResponses[tradeId][responseId];
        Trade memory trade = Trades[tradeId];

        require(Glitch.isApprovedForAll(Trades[tradeId].seller, address(this)), "Seller is not approved.");
        require(Glitch.isApprovedForAll(Glitch.ownerOf(tradeTokenId), address(this)), "Buyer is not approved.");

        trade.tokenId_2 = tradeTokenId;
        trade.buyer = Glitch.ownerOf(tradeTokenId);
        trade.isActive = false;
        Trades[tradeId] = trade;
        activeTrades--;

        Glitch.safeTransferFrom(trade.seller, trade.buyer, trade.tokenId_1);
        Glitch.safeTransferFrom(trade.buyer, trade.seller, trade.tokenId_2);

        emit TradeEvent(tradeId, trade.tokenId_1, trade.tokenId_2, trade.seller, trade.buyer);
    }

    // Cancel Listing
    function cancelListing(uint256 orderId) public {
        require(Orders[orderId].seller == msg.sender, "You are not the seller.");
        Orders[orderId].isActive = false;
        activeOrders--;
    }

    // Cancel TradeSeek
    function cancelTradeSeek(uint256 tradeId) public {
        require(Trades[tradeId].seller == msg.sender, "You are not the seller.");
        Trades[tradeId].isActive = false;
        activeTrades--;
    }

    // Cancel TradeResponse
    function cancelTradeResponse(uint256 tradeId, uint256 tokenId) public {
        require(Glitch.ownerOf(tokenId) == msg.sender, "You must be owner to cancel trade.");
        for(uint256 i = 0; i <= Trades[tradeId].responses; i++) {
            if(TradeResponses[tradeId][i] == tokenId) {
                TradeResponses[tradeId][i] = 0;
            }
        }
    }

    // Get Active Orders
    function getActiveOrders() view public returns(uint256[] memory result) {
        result = new uint256[](activeOrders);
        uint256 resultIndex = 0;
        for (uint256 t = 1; t <= orderIds.current(); t++) {
            if (Orders[t].isActive) {
                result[resultIndex] = t;
                resultIndex++;
            }
        }
    }

    // Get Active Trades
    function getActiveTrades() view public returns(uint256[] memory result) {
        result = new uint256[](activeTrades);
        uint256 resultIndex = 0;
        for (uint256 t = 1; t <= tradeIds.current(); t++) {
            if (Trades[t].isActive) {
                result[resultIndex] = t;
                resultIndex++;
            }
        }
    }

    function getGlitchStatus(uint256 tokenId) public view returns (Status memory status) {
        status = Status(0, 0, 0);

        // Check active active orders
        for (uint256 t = 1; t <= orderIds.current(); t++) {
            if (Orders[t].tokenId == tokenId && Orders[t].isActive) {
                status.forSale = t;
            }
        }

        // Check active trades
        for (uint256 t = 1; t <= tradeIds.current(); t++) {
            if (Trades[t].tokenId_1 == tokenId && Trades[t].isActive) {
                status.forTrade= t;
            } else {
                for(uint256 k=1; k<=Trades[t].responses; k++) {
                    if(TradeResponses[t][k] == tokenId && Trades[t].isActive) {
                        status.forTradeResponse = t;
                    }
                }
            }
        }
    }

    function setRoyalty(uint256 _royalty) public onlyOwner {
        royalty = _royalty;
    }

    function setRoyaltyAddress(address _royaltyAddress) public onlyOwner {
        royaltyAddress = _royaltyAddress;
    }

    function setActive(bool _active) public onlyOwner {
        active = _active;
    }

    /*
    *   Money management.
    */
    function withdraw() public payable onlyOwner {
        require(payable(royaltyAddress).send(address(this).balance));
    }
}
