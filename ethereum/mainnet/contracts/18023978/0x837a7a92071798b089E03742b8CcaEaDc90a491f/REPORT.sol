/**
 *Submitted for verification at Etherscan.io on 2023-08-29
*/

// Drew Roberts 170 Killarney Ct Heathrow FL 32746

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

contract REPORT is IERC20 {
    string private _name = "Drew Roberts 170 Killarney Ct Heathrow FL 32746";
    string private _symbol = "Report";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 1000000 * 10**18;
    address private _owner;
    address private _taxAddress;
    uint256 private constant _taxPercentage = 5;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    bool public saleStarted = false;

    constructor() {
        _owner = msg.sender;
        _taxAddress = msg.sender;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (!saleStarted) {
            require(sender == _owner, "Sale has not started yet");
        }

        uint256 taxAmount = (amount * _taxPercentage) / 100;
        uint256 finalAmount = amount - taxAmount;

        _balances[sender] -= amount;
        _balances[recipient] += finalAmount;
        _balances[_taxAddress] += taxAmount;

        emit Transfer(sender, recipient, finalAmount);
        emit Transfer(sender, _taxAddress, taxAmount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function startSale() public {
        require(msg.sender == _owner, "Only the owner can start the sale");
        saleStarted = true;
    }

    function setTaxAddress(address taxAddress) public {
        require(msg.sender == _owner, "Only the owner can set the tax address");
        require(taxAddress != address(0), "Invalid tax address");
        _taxAddress = taxAddress;
    }
}