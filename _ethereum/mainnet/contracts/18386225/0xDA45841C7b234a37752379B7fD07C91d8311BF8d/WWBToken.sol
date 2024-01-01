// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.7.0 <0.9.0;

// import "./SafeMath.sol";


// Token contract
contract WWBToken {
    // Token details
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;
    
    // Mapping of balances
    mapping(address => uint256) public balanceOf;
    
    // Event for token transfer
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // Event for token burn
    event Burn(address indexed from, uint256 value);
    
    // Constructor
    constructor() {
        name = "Helloween Token";
        symbol = "HEN";
        
        totalSupply = 1 * 10**9;
        
        // Assign initial supply to contract creator
        balanceOf[msg.sender] = totalSupply;
    }
    
    // Function to transfer tokens
    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0), "Invalid address");
        require(value > 0, "Invalid value");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        
        uint256 transactionFee = (value * 5) / 100; // Calculate 5% transaction fee
        uint256 tokensToTransfer = value - transactionFee; // Deduct transaction fee from transfer amount
        
        balanceOf[msg.sender] -= value; // Deduct tokens from sender
        balanceOf[to] += tokensToTransfer; // Add tokens to receiver
        balanceOf[address(0)] += transactionFee; // Add transaction fee to burn address
        
        emit Transfer(msg.sender, to, tokensToTransfer);
        emit Burn(msg.sender, transactionFee);
        
        return true;
    }
    
    // Function to burn tokens
    function burn(uint256 value) public returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        
        balanceOf[msg.sender] -= value; // Deduct tokens from sender
        totalSupply -= value; // Deduct tokens from total supply
        
        emit Burn(msg.sender, value);
        
        return true;
    }
}