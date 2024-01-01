// SPDX-License-Identifier: MIT

/**
Telegram: https://t.me/dorkcoin
Twitter : https://twitter.com/SrPetersETH

*/


pragma solidity ^0.8.0;

contract HIGH {
    string public name = "HIGH";
    string public symbol = "HIGH";
    uint8 public decimals = 18; // Assuming 18 decimals for most tokens
    uint256 public totalSupply = 999999999999 * 10**uint256(decimals);
    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event LPLocked(address indexed account, uint256 amount);

    constructor() {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "HIGH");
        _;
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(_to != address(0), "HIGHHIGH");
        require(balanceOf[msg.sender] >= _value, "HIGHHIGHHIGH");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        require(_from != address(0), "1HIGH");
        require(_to != address(0), "2HIGH");
        require(balanceOf[_from] >= _value, "3HIGH");
        require(allowance[_from][msg.sender] >= _value, "4HIGH");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    function renounceOwnership() external onlyOwner {
        owner = address(0);
    }
}