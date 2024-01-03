// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Budycoin {
    string public constant name = "Budycoin";
    string public constant symbol = "BUDY";
    uint8 public constant decimals = 18;  // Nombre de décimales, généralement 18

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    address private _owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == _owner, "BUDY: only owner can call this function");
        _;
    }

    constructor() {
        _owner = msg.sender;
        // Définir l'approvisionnement initial à 1 milliard de BUDYcoins
        _mint(msg.sender, 1000000000 * 10**decimals);
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowances[from][msg.sender] - value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(from != address(0), "BUDYcoin: transfer from the zero address");
        require(to != address(0), "BUDYcoin: transfer to the zero address");

        _balances[from] -= value;
        _balances[to] += value;

        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal onlyOwner {
        require(account != address(0), "BUDYcoin: mint to the zero address");

        _totalSupply += value;
        _balances[account] += value;

        emit Transfer(address(0), account, value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "BUDYcoin: approve from the zero address");
        require(spender != address(0), "BUDYcoin: approve to the zero address");

        _allowances[owner][spender] = value;

        emit Approval(owner, spender, value);
    }
}