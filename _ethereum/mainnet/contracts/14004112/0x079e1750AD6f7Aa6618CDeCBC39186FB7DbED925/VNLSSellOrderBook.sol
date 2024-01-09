// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./IVNLSSellOrderBook.sol";
import "./IVirtualBitcoin.sol";

contract VNLSSellOrderBook is IVNLSSellOrderBook {
    
    IVirtualBitcoin vbtc;

    struct SellOrder {
        address seller;
        uint256 amount;
        uint256 price;
    }
    SellOrder[] public orders;

    constructor(IVirtualBitcoin _vbtc) {
        vbtc = _vbtc;
    }

    function count() override external view returns (uint256) {
        return orders.length;
    }

    function get(uint256 orderId) override external view returns (address seller, uint256 amount, uint256 price) {
        SellOrder memory order = orders[orderId];
        return (order.seller, order.amount, order.price);
    }

    function sell(uint256 amount, uint256 price) override external {
        vbtc.transferFrom(msg.sender, address(this), amount);
        uint256 orderId = orders.length;
        orders.push(SellOrder({
            seller: msg.sender,
            amount: amount,
            price: price
        }));
        emit Sell(orderId, msg.sender, amount, price);
    }

    function remove(uint256 orderId) internal {
        delete orders[orderId];
        emit Remove(orderId);
    }

    function buy(uint256 orderId) override payable external {
        SellOrder storage order = orders[orderId];
        uint256 amount = order.amount * msg.value / order.price;
        vbtc.transfer(msg.sender, amount);
        order.amount -= amount;
        order.price -= msg.value;
        address seller = order.seller;
        if (order.amount == 0) {
            remove(orderId);
        }
        payable(seller).transfer(msg.value);
        emit Buy(orderId, msg.sender, amount);
    }

    function cancel(uint256 orderId) override external {
        SellOrder memory order = orders[orderId];
        require(order.seller == msg.sender);
        vbtc.transfer(msg.sender, order.amount);
        remove(orderId);
        emit Cancel(orderId);
    }
}
