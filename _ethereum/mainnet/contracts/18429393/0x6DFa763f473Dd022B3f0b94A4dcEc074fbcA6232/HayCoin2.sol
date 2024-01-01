// SPDX-License-Identifier: MIT
// https://t.me/haycoin2

pragma solidity ^0.8.19;

contract HayCoin2 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromMaxTx;

    address private _owner;

    uint256 private _totalSupply;

    bool public tradingActive;

    uint256 public maxTransaction;
    uint8 private _decimals = 9;

    string private _name;
    string private _symbol;

    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }

    event Approval(
        address indexed from,
        address indexed spender,
        uint256 amount
    );
    event Transfer(address indexed from, address indexed to, uint256 amount);

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        address owner_
    ) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;
        _balances[owner_] = totalSupply_;
        emit Transfer(address(0), owner_, totalSupply_);
        _owner = owner_;
        maxTransaction = (totalSupply_ / 100) * 2;
        _isExcludedFromMaxTx[owner_] = true;
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

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function balanceOf(address _address) public view returns (uint256) {
        return _balances[_address];
    }

    function allowance(address from, address to) public view returns (uint256) {
        return _allowances[from][to];
    }

    function isExcludedFromMaxTx(address _address) public view returns (bool) {
        return _isExcludedFromMaxTx[_address];
    }

    function renounceOwnership() external onlyOwner {
        _owner = address(0);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        _owner = newOwner;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address from,
        address spender,
        uint256 amount
    ) internal {
        _allowances[from][spender] = amount;
        emit Approval(from, spender, amount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        _approve(from, msg.sender, _allowances[from][msg.sender] - amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(_balances[from] >= amount);
        if (!tradingActive) {
            require(_isExcludedFromMaxTx[from] ||_isExcludedFromMaxTx[to]);
        }
        if (!_isExcludedFromMaxTx[from] && !_isExcludedFromMaxTx[to]) {
            require(amount <= maxTransaction);
        }
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function enableTrading() external onlyOwner {
        tradingActive = true;
    }

    function removeLimits() external onlyOwner {
        maxTransaction = _totalSupply;
    }
}