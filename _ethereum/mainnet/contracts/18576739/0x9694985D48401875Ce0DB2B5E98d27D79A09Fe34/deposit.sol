// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IERC20.sol";
import "./Ownable.sol";

contract DepositContract is Ownable {
    IERC20 public token;
    mapping(address => uint256) public balances;
    address[] private depositors;
    address public _owner;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(uint256 amount);

    constructor(IERC20 _token) Ownable() {
        token = _token;
       
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        if (balances[msg.sender] == 0) {
            depositors.push(msg.sender);
        }
        balances[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }

    function getDepositors()
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        uint256[] memory amounts = new uint256[](depositors.length);
        for (uint i = 0; i < depositors.length; i++) {
            amounts[i] = balances[depositors[i]];
        }
        return (depositors, amounts);
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        require(token.transfer(owner(), balance), "Transfer failed");
        emit Withdrawal(balance);
    }

    function withdrawAmount(uint256 amount) external onlyOwner {
        require(
            amount > 0 && amount <= token.balanceOf(address(this)),
            "Invalid withdrawal amount"
        );
        require(token.transfer(owner(), amount), "Transfer failed");
        emit Withdrawal(amount);
    }
}