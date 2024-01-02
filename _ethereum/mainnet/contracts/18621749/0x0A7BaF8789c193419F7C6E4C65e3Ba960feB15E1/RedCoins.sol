// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RedCoins {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    address private contractOwner;
    uint256 private creatorFeePercentage;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner can perform this action");
        _;
    }

    constructor() {
        name = "RedCoins";
        symbol = "RED";
        decimals = 18;
        totalSupply = 0;
        contractOwner = msg.sender;
        creatorFeePercentage = 10;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function allowance(address ownerAddress, address spender) public view returns (uint256) {
        return allowances[ownerAddress][spender];
    }

    function mint(uint256 amount) public {
        require(amount > 0, "Amount must be greater than zero");

        balances[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);

        uint256 creatorFee = (amount * creatorFeePercentage) / 100;
        balances[contractOwner] += creatorFee;
        totalSupply += creatorFee;
        emit Transfer(address(0), contractOwner, creatorFee);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(amount > 0, "Amount must be greater than zero");
        require(amount <= balances[msg.sender], "Insufficient balance");

        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        require(amount > 0, "Amount must be greater than zero");

        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        require(amount > 0, "Amount must be greater than zero");
        require(amount <= balances[from], "Insufficient balance");
        require(amount <= allowances[from][msg.sender], "Insufficient allowance");

        balances[from] -= amount;
        balances[to] += amount;
        allowances[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(addedValue > 0, "Added value must be greater than zero");

        allowances[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);

        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(subtractedValue > 0, "Subtracted value must be greater than zero");
        require(subtractedValue <= allowances[msg.sender][spender], "Decreased allowance below zero");

        allowances[msg.sender][spender] -= subtractedValue;
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);

        return true;
    }

    function setCreatorFeePercentage(uint256 feePercentage) public onlyOwner {
        require(feePercentage >= 0 && feePercentage <= 100, "Invalid fee percentage");

        creatorFeePercentage = feePercentage;
    }

    function updateContract(address newContractAddress) public onlyOwner {
        require(newContractAddress != address(0), "Invalid contract address");

        selfdestruct(payable(newContractAddress));
    }
}