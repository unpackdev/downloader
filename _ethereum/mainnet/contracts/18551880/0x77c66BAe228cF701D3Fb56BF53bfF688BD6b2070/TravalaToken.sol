// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TravalaToken {
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    string public name = "Travala";
    string public symbol = "TRVL";
    uint256 public totalSupply = 100000000 * 10**18; // 100 million tokens
    uint256 public initialPrice = 0.0001 * 10**18; // $0.0001
    uint256 public sellTaxRate = 5; // 5% sell tax

    address public contractOwner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Not the owner");
        _;
    }

    constructor() {
        contractOwner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        uint256 afterTaxAmount = applySellTax(value);
        require(balances[msg.sender] >= afterTaxAmount, "Insufficient balance");

        balances[msg.sender] -= afterTaxAmount;
        balances[to] += afterTaxAmount;

        emit Transfer(msg.sender, to, afterTaxAmount);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        uint256 afterTaxAmount = applySellTax(value);
        require(balances[from] >= afterTaxAmount, "Insufficient balance");
        require(allowances[from][msg.sender] >= afterTaxAmount, "Insufficient allowance");

        balances[from] -= afterTaxAmount;
        balances[to] += afterTaxAmount;
        allowances[from][msg.sender] -= afterTaxAmount;

        emit Transfer(from, to, afterTaxAmount);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function getAllowance(address owner, address spender) external view returns (uint256) {
        return allowances[owner][spender];
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function applySellTax(uint256 amount) internal view returns (uint256) {
        uint256 taxAmount = (amount * sellTaxRate) / 100;
        return amount - taxAmount;
    }

    // Additional functions for owner to manage contract parameters
    function setSellTaxRate(uint256 _sellTaxRate) external onlyOwner {
        require(_sellTaxRate <= 100, "Sell tax rate must be 100 or less");
        sellTaxRate = _sellTaxRate;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        contractOwner = newOwner;
    }
}