// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC20Token {
    string public name = "dontcarenoproblemlifeisliterallysoeasy";
    string public symbol = "PROBLEM";
    uint8 public decimals = 18;
    uint256 public totalSupply = 99000000000 * 10 ** uint256(decimals);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {
        _balances[msg.sender] = totalSupply;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier requireSufficientBalance(address from, uint256 value) {
        require(_balances[from] >= value, "ERC20: insufficient balance");
        _;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 value) public requireSufficientBalance(msg.sender, value) returns (bool) {
        require(to != address(0), "ERC20: transfer to the zero address");
        _transfer(msg.sender, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        _balances[from] -= value;
        _balances[to] += value;
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function _approve(address owner, address spender, uint256 value) internal {
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function transferFrom(address from, address to, uint256 value) public requireSufficientBalance(from, value) returns (bool) {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_allowances[from][msg.sender] >= value, "ERC20: allowance too low");
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowances[from][msg.sender] - value);
        return true;
    }
}