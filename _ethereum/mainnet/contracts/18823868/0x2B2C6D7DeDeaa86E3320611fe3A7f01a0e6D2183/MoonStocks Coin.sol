// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MoonStocksCoin {
string public name = "MoonStocks Coin";
string public symbol = "MSTX";
uint256 public totalSupply = 250_000_000 * 10**18; // 250 million tokens
uint8 public constant decimals = 18;
address public owner;
uint256 public constant creatorFeePercent = 10;
uint256 public constant taxPercent = 2;

mapping(address => uint256) public balanceOf;
mapping(address => mapping(address => uint256)) public allowance;

event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed ownerAddr, address indexed spender, uint256 value);

constructor() {
owner = msg.sender;
balanceOf[msg.sender] = totalSupply;
}

modifier onlyOwner() {
require(msg.sender == owner, "Not the owner");
_;
}

function transfer(address to, uint256 value) external returns (bool) {
uint256 fee = (value * creatorFeePercent) / 100;
_transfer(msg.sender, owner, fee);
_transfer(msg.sender, to, value - fee);
return true;
}

function transferFrom(address from, address to, uint256 value) external returns (bool) {
uint256 fee = (value * creatorFeePercent) / 100;
_transfer(from, owner, fee);
_transfer(from, to, value - fee);
_approve(from, msg.sender, allowance[from][msg.sender] - value);
return true;
}

function buyTokens() external payable {
uint256 amount = (msg.value * (10**18)) / ((100 + taxPercent) * 10**18 / 100);
_transfer(owner, msg.sender, amount);
}

function sellTokens(uint256 value) external {
uint256 tax = (value * taxPercent) / 100;
_transfer(msg.sender, owner, tax);
_transfer(msg.sender, address(0), value - tax);
payable(owner).transfer(tax);
}

function _transfer(address from, address to, uint256 value) internal {
require(from != address(0), "Transfer from the zero address");
require(to != address(0), "Transfer to the zero address");
require(balanceOf[from] >= value, "Insufficient balance");

balanceOf[from] -= value;
balanceOf[to] += value;

emit Transfer(from, to, value);
}

function _approve(address ownerAddr, address spender, uint256 value) internal {
require(ownerAddr != address(0), "Approve from the zero address");
require(spender != address(0), "Approve to the zero address");

allowance[ownerAddr][spender] = value;
emit Approval(ownerAddr, spender, value);
}
}
