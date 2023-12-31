// t.me/CfangIndexPortal
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract CFANG is IERC20 {
    string public name = "Charlotte Fang Index";
    string public symbol = "CFANG";
    uint8 public decimals = 18;
    uint256 private _totalSupply = 10_000_000 * 10**uint256(decimals);
    address public owner;
    uint256 public maxTokensPerWallet = 1_000_000 * 10**uint256(decimals);
    uint256 public maxTokensPerTransaction = 200_000 * 10**uint256(decimals);
    uint256 public buyTax = 5; // Percentage
    uint256 public sellTax = 5; // Percentage
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
        _balances[msg.sender] = _totalSupply;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(_allowances[sender][msg.sender] >= amount, "Allowance exceeded");
        _allowances[sender][msg.sender] -= amount;
        _transfer(sender, recipient, amount);
        return true;
    }

    function startSale() external onlyOwner {
        // Implement sale logic here
    }

    function updateBuyTax(uint256 _newTax) external onlyOwner {
        require(_newTax <= 100, "Tax percentage must be between 0 and 100");
        buyTax = _newTax;
    }

    function updateSellTax(uint256 _newTax) external onlyOwner {
        require(_newTax <= 100, "Tax percentage must be between 0 and 100");
        sellTax = _newTax;
    }

    function updateMaxTokensPerWallet(uint256 _newMax) external onlyOwner {
        maxTokensPerWallet = _newMax;
    }

    function updateMaxTokensPerTransaction(uint256 _newMax) external onlyOwner {
        maxTokensPerTransaction = _newMax;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_balances[sender] >= amount, "Insufficient balance");

        if (sender != owner && recipient != owner) {
            require(amount <= maxTokensPerTransaction, "Exceeds max tokens per transaction");
            require(_balances[recipient] + amount <= maxTokensPerWallet, "Exceeds max tokens per wallet");
        }

        uint256 taxAmount = 0;
        if (sender == owner) {
            taxAmount = (amount * buyTax) / 100;
        } else {
            taxAmount = (amount * sellTax) / 100;
        }

        uint256 transferAmount = amount - taxAmount;
        _balances[sender] -= amount;
        _balances[recipient] += transferAmount;
        _balances[owner] += taxAmount;

        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, owner, taxAmount);
    }
}