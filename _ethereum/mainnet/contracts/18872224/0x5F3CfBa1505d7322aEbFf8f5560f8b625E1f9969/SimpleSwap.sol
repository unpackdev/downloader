// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC20.sol";
import "./EnumerableSet.sol";

// Lets users swap erc-20 tokens for eth in a trustless way

contract SimpleSwap {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Order {
        address maker;
        IERC20 token;
        uint256 amount; //amount of tokens to sell
        uint256 price; //price in eth
        bool filled;
    }

    // all orders that have ever been created
    Order[] private orders;

    // a small fee is paid by the address filling an order
    uint256 public constant FEE = 0.002 ether;
    address public feeRecipient;

    // active orders for a token
    mapping(IERC20 => EnumerableSet.UintSet) private tokenActiveOrders;

    // active orders for a user
    mapping(address => EnumerableSet.UintSet) private userActiveOrders;

    // Events
    event OrderCreated(uint256 id, address maker, IERC20 token, uint256 amount, uint256 price);
    event OrderFilled(uint256 id, address maker, IERC20 token, uint256 amount, uint256 price);
    event OrderCancelled(uint256 id, address maker, IERC20 token, uint256 amount, uint256 price);

    constructor() {
        feeRecipient = msg.sender;
    }

    // Create an order to sell tokens for eth
    // requires the user to approve the contract to spend their tokens
    function createOrder(IERC20 token, uint256 lotAmount, uint256 saleAmountEth) public returns (uint256 orderId) {
        require(lotAmount > 0, "lot amount must be greater than 0");
        require(saleAmountEth > 0, "sale amount must be greater than 0");
        require(token.balanceOf(msg.sender) >= lotAmount, "not enough tokens to sell");
        require(token.allowance(msg.sender, address(this)) >= lotAmount, "not enough allowance to sell");

        // transfer the tokens from the maker to the contract
        token.transferFrom(msg.sender, address(this), lotAmount);

        // create the order
        orders.push(Order(msg.sender, token, lotAmount, saleAmountEth, false));
        orderId = orders.length - 1;

        // add the order to the active orders
        tokenActiveOrders[token].add(orderId);
        userActiveOrders[msg.sender].add(orderId);

        emit OrderCreated(orderId, msg.sender, token, lotAmount, saleAmountEth);
    }

    // Cancel an order that has not been filled
    function cancelOrder(uint256 id) public {
        Order storage order = orders[id];
        require(order.maker == msg.sender, "not order maker");
        require(order.filled == false, "order already filled");
        order.filled = true;

        // return the tokens to the maker
        order.token.transfer(msg.sender, order.amount);

        // remove the order from the active orders
        tokenActiveOrders[order.token].remove(id);
        userActiveOrders[order.maker].remove(id);

        emit OrderCancelled(id, msg.sender, order.token, order.amount, order.price);
    }

    // Fill an order by sending eth to the contract
    // need to send the exact amount of eth specified in the order plus the FEE
    function fillOrder(IERC20 token, uint256 orderId) public payable {
        Order storage order = orders[orderId];

        require(order.filled == false, "order already filled");
        require(msg.value == order.price + FEE, "incorrect amount of eth sent");

        order.filled = true;

        // transfer the eth to the maker and the fee to the feeRecipient
        payable(order.maker).transfer(order.price);
        payable(feeRecipient).transfer(FEE);

        // transfer the tokens to the filler
        token.transfer(msg.sender, order.amount);

        tokenActiveOrders[token].remove(orderId);
        userActiveOrders[order.maker].remove(orderId);

        emit OrderFilled(orderId, msg.sender, order.token, order.amount, order.price);
    }

    //get paged active orders for a token
    function getTokenActiveOrders(IERC20 token, uint256 startIndex, uint256 pageSize)
        public
        view
        returns (uint256[] memory ids, Order[] memory activeOrders)
    {
        EnumerableSet.UintSet storage orderIds = tokenActiveOrders[token];
        uint256 length = orderIds.length();
        uint256 endIndex = startIndex + pageSize;
        if (endIndex > length) {
            endIndex = length;
        }
        uint256 resultLength = endIndex - startIndex;

        ids = new uint256[](resultLength);
        activeOrders = new Order[](resultLength);

        for (uint256 i = startIndex; i < endIndex; i++) {
            ids[i - startIndex] = orderIds.at(i);
            uint256 orderId = orderIds.at(i);
            activeOrders[i - startIndex] = orders[orderId];
        }
    }

    function getTokenActiveOrdersCount(IERC20 token) public view returns (uint256 count) {
        count = tokenActiveOrders[token].length();
    }

    //get paged active orders for a user
    function getUserActiveOrders(address maker, uint256 startIndex, uint256 pageSize)
        public
        view
        returns (uint256[] memory ids, Order[] memory activeOrders)
    {
        EnumerableSet.UintSet storage orderIds = userActiveOrders[maker];
        uint256 length = orderIds.length();
        uint256 endIndex = startIndex + pageSize;
        if (endIndex > length) {
            endIndex = length;
        }
        uint256 resultLength = endIndex - startIndex;

        ids = new uint256[](resultLength);
        activeOrders = new Order[](resultLength);

        for (uint256 i = startIndex; i < endIndex; i++) {
            ids[i - startIndex] = orderIds.at(i);
            uint256 orderId = orderIds.at(i);
            activeOrders[i - startIndex] = orders[orderId];
        }
    }

    function getUserActiveOrdersCount(address maker) public view returns (uint256 count) {
        count = userActiveOrders[maker].length();
    }

    //get an order by id
    function getOrder(uint256 index) public view returns (Order memory order) {
        order = orders[index];
    }

    function getOrderCount() public view returns (uint256 count) {
        count = orders.length;
    }
}
