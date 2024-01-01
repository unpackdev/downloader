// SPDX-License-Identifier: MIT

// Chat Portal - https://t.me/WitchErcPortal

pragma solidity 0.8.16;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract WITCH is IERC20 {
    string public constant name = "WITCH";
    string public constant symbol = "WITCH";
    uint256 public constant decimals = 9;
    uint256 public constant totalSupply = 666 * 10 ** decimals;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(
        address to,
        uint256 amount
    ) external override returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        if (allowance[from][msg.sender] < type(uint).max) {
            allowance[from][msg.sender] -= amount;
        }
        return _transfer(from, to, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private returns (bool) {
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
}