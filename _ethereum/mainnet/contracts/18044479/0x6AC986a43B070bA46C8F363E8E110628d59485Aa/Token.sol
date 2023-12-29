// SPDX-License-Identifier: UNLICENSED


pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 100000000 * 10 ** 18;
    string public name = "LuckyDip";
    string public symbol = "LDIP";
    uint public decimals = 18;
    uint public feeRate1 = 1;
    uint public feeRate2 = 4;
    
    address public feeAddress1 = 0xDFafF9A3A02bC41553f5D60E2f99f4c515217599;
    address public feeAddress2 = 0x99c58FfC1933545B591d95D7567C9820A4A1D059;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        
        uint fee1 = (value * feeRate1) / 100;
        uint fee2 = (value * feeRate2) / 100;
        uint transferAmount = value - fee1 - fee2;
        
        balances[to] += transferAmount;
        balances[msg.sender] -= value;
        
        balances[feeAddress1] += fee1;
        balances[feeAddress2] += fee2;
        
        emit Transfer(msg.sender, to, transferAmount);
        emit Transfer(msg.sender, feeAddress1, fee1);
        emit Transfer(msg.sender, feeAddress2, fee2);
        
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        
        uint fee1 = (value * feeRate1) / 100;
        uint fee2 = (value * feeRate2) / 100;
        uint transferAmount = value - fee1 - fee2;
        
        balances[to] += transferAmount;
        balances[from] -= value;
        
        balances[feeAddress1] += fee1;
        balances[feeAddress2] += fee2;
        
        emit Transfer(from, to, transferAmount);
        emit Transfer(from, feeAddress1, fee1);
        emit Transfer(from, feeAddress2, fee2);
        
        return true;
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}