// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Unlockedusdt {
    // Token details
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    // Mapping to track balances
    mapping(address => uint256) public balanceOf;

    // Mapping for allowance
    mapping(address => mapping(address => uint256)) public allowance;

    // Event to log transfers
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Event to log approvals
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Event to log minting
    event Mint(address indexed to, uint256 value);

    // Contract owner
    address private _owner;

    // Modifier to restrict access to the owner
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the owner can call this function");
        _;
    }

    // Constructor to initialize the token
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _initialSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initialSupply;
        balanceOf[msg.sender] = _initialSupply;
        _owner = msg.sender;
    }

    // Function to transfer tokens
    function transfer(address _to, uint256 _amount) public returns (bool) {
        require(_amount <= balanceOf[msg.sender], "Insufficient balance");

        balanceOf[msg.sender] -= _amount;
        balanceOf[_to] += _amount;

        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    // Function to approve a spender and set an allowance
    function approve(address _spender, uint256 _amount) public returns (bool) {
        allowance[msg.sender][_spender] = _amount;

        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    // Function to transfer tokens from one account to another
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool) {
        require(_amount <= balanceOf[_from], "Insufficient balance");
        require(_amount <= allowance[_from][msg.sender], "Insufficient allowance");

        balanceOf[_from] -= _amount;
        balanceOf[_to] += _amount;
        allowance[_from][msg.sender] -= _amount;

        emit Transfer(_from, _to, _amount);
        return true;
    }

    // Function to mint new tokens
    function mint(address _to, uint256 _amount) public onlyOwner {
        require(_to != address(0), "Invalid address");
        
        balanceOf[_to] += _amount;
        totalSupply += _amount;
        
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
    }

    // Function to get the contract owner
    function owner() public view returns (address) {
        return _owner;
    }
}