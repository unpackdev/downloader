// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyToken {
    // Token details
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    // Mapping to track balances
    mapping(address => uint256) public balanceOf;

    // Event to log transfers
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Constructor to initialize the token
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _initialSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initialSupply;
        balanceOf[msg.sender] = _initialSupply;
    }

    // Function to mint new tokens
    function mint(address _to, uint256 _amount) public {
        require(msg.sender == owner(), "Only the owner can mint tokens");
        
        balanceOf[_to] += _amount;
        totalSupply += _amount;
        emit Transfer(address(0), _to, _amount);
    }

    // Function to burn tokens
    function burn(uint256 _amount) public {
        require(balanceOf[msg.sender] >= _amount, "Insufficient balance");

        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        emit Transfer(msg.sender, address(0), _amount);
    }

    // Function to get the contract owner
    function owner() public view returns (address) {
        return owner();
    }
}