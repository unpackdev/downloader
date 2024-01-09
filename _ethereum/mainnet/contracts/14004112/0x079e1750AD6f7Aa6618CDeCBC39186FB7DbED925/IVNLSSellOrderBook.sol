// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

interface IVNLSSellOrderBook {

    event Sell(uint256 indexed orderId, address indexed seller, uint256 amount, uint256 price);
    event Remove(uint256 indexed orderId);
    event Buy(uint256 indexed orderId, address indexed buyer, uint256 amount);
    event Cancel(uint256 indexed orderId);

    function count() external view returns (uint256);
    function get(uint256 orderId) external view returns (address seller, uint256 amount, uint256 price);
    function sell(uint256 amount, uint256 price) external;
    function buy(uint256 orderId) payable external;
    function cancel(uint256 orderId) external;
}
