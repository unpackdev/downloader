// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IVirtualBitcoin {

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event BuyPizza(address indexed owner, uint256 indexed pizzaId, uint256 power);
    event ChangePizza(address indexed owner, uint256 indexed pizzaId, uint256 power);
    event SellPizza(address indexed owner, uint256 indexed pizzaId);
    event Mine(address indexed owner, uint256 indexed pizzaId, uint256 subsidy);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);
    function transfer(address to, uint256 amount) external returns (bool success);
    function transferFrom(address from, address to, uint256 amount) external returns (bool success);
    function approve(address spender, uint256 amount) external returns (bool success);
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    function pizzaPrice(uint256 power) external view returns (uint256);
    function pizzaCount() external view returns (uint256);
    function subsidyAt(uint256 blockNumber) external view returns (uint256);
    function buyPizza(uint256 power) external returns (uint256);
    function sellPizza(uint256 pizzaId) external;
    function changePizza(uint256 pizzaId, uint256 power) external;
    function powerOf(uint256 pizzaId) external view returns (uint256);
    function subsidyOf(uint256 pizzaId) external view returns (uint256);
    function mine(uint256 pizzaId) external returns (uint256);
}