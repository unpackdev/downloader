// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

contract MaterixToken {
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    error TransferAmountExceedsAllowance(address from, address to, uint256 amount, uint256 allowance);
    error TransferAmountExceedsBalance(address from, address to, uint256 amount, uint256 balance);

    constructor(address to, uint256 amount) {
        balanceOf[to] += amount;
        totalSupply += amount;

        emit Transfer(address(0), to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        if (from != msg.sender) {
            uint256 _allowance = allowance[from][msg.sender];
            if (_allowance < amount) {
                revert TransferAmountExceedsAllowance(from, to, amount, _allowance);
            }
        }

        _transfer(from, to, amount);

        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);

        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function name() external pure returns (string memory) {
        return "Materix";
    }


    function symbol() external pure returns (string memory) {
        return "MTFB";
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        uint256 balance = balanceOf[from];
        if (balance < amount) {
            revert TransferAmountExceedsBalance(from, to, amount, balance);
        }
        unchecked {
            balanceOf[from] = balance - amount;
        }
        balanceOf[to] += amount;

        emit Transfer(from, to, amount);
    }
}