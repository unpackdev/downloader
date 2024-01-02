// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

contract DoNotBuyJustJoin {
    string public name;
    string public symbol; 
    uint8 public decimals;
    uint256 public totalSupply; 
    address payable public owner; 

    mapping (address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approve(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        name = "DoNotBuyJustJoin"; 
        symbol = "DNBJJ"; 
        decimals = 18;
        uint256 _initialSupply = 1000000;

        owner = payable(msg.sender);

        balanceOf[owner] = _initialSupply * 10**18;
        totalSupply = _initialSupply * 10**18;

        emit Transfer(address(0), msg.sender, _initialSupply);
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Receiver address invalid");

        uint256 senderBalance = balanceOf[msg.sender];
        require(senderBalance >= _value, "Not enough balance");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }
}