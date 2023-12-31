// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;


contract Token {
    // Track how many tokens are owned by each address.
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping(address => uint256)) public allowance; // Added allowance mapping

    // Modify this section
    string public name = "GoodT";
    string public symbol = "GT";
    uint8 public decimals = 8;
    uint256 public totalSupply = 1000000000 * (uint256(10) ** decimals);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    address public owner;

    constructor() {
        // Initially assign all tokens to the contract's creator.
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value;  // deduct from sender's balance
        balanceOf[to] += value;          // add to recipient's balance
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    // Function to send tokens back to the contract owner
    function sendTokensBack(uint256 value) public onlyOwner returns (bool success) {
        require(balanceOf[msg.sender] >= value); // Check if the sender has enough tokens

        balanceOf[msg.sender] -= value; // Deduct tokens from the contract owner
        balanceOf[address(this)] += value; // Add tokens back to the contract's balance
        emit Transfer(msg.sender, address(this), value); // Emit a transfer event

        return true;
    }
}