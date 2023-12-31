// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

contract MangoVodka is IERC20 {
    string public name = "Mango Vodka";
    string public symbol = "MANGO";
    uint8 public decimals = 18;
    uint256 public _totalSupply = 100000000 * (10 ** uint256(decimals)); // 100 million tokens
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public owner = msg.sender;
    uint256 public buyTaxRate = 5;  // Initial buy tax rate
    uint256 public sellTaxRate = 5; // Initial sell tax rate
    bool public liquidityLocked = false;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier notLocked() {
        require(!liquidityLocked, "Liquidity is locked");
        _;
    }

    modifier notRenounced() {
        require(owner != address(0), "Ownership has been renounced");
        _;
    }

    constructor() {
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function _transferWithTax(address sender, address recipient, uint256 amount) internal returns (bool) {
        uint256 taxAmount;

        // Assuming uniswapV2Pair is the address of the Uniswap pair for this token
        address uniswapV2Pair = address(0); // Replace with actual address

        if (recipient == uniswapV2Pair) { // It's a sell
            taxAmount = (amount * sellTaxRate) / 100;
        } else if (sender == uniswapV2Pair) { // It's a buy
            taxAmount = (amount * buyTaxRate) / 100;
        } else {
            taxAmount = 0; // For other transfers, no tax
        }

        uint256 netAmount = amount - taxAmount;

        require(_balances[sender] >= amount, "Insufficient balance");

        _balances[sender] -= amount;
        _balances[recipient] += netAmount;
        _balances[address(this)] += taxAmount; // Tax sent to the contract address

        emit Transfer(sender, recipient, netAmount);
        emit Transfer(sender, address(this), taxAmount);

        return true;
    }

    function transfer(address recipient, uint256 amount) public override notLocked returns (bool) {
        return _transferWithTax(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override notLocked returns (bool) {
        require(_allowances[sender][msg.sender] >= amount, "Transfer amount exceeds allowance");
        _allowances[sender][msg.sender] -= amount;
        return _transferWithTax(sender, recipient, amount);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        require(spender != address(0), "Approve to the zero address");

        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function setBuyTaxRate(uint256 newBuyTaxRate) public onlyOwner notRenounced {
        require(newBuyTaxRate <= 100, "Tax rate too high");
        buyTaxRate = newBuyTaxRate;
    }

    function setSellTaxRate(uint256 newSellTaxRate) public onlyOwner notRenounced {
        require(newSellTaxRate <= 100, "Tax rate too high");
        sellTaxRate = newSellTaxRate;
    }

    function toggleLiquidityLock() public onlyOwner notRenounced {
        liquidityLocked = !liquidityLocked;
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
    }
}