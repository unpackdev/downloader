// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Arbitrage {
    address public owner;
    mapping(address => uint256) public balances;

    event Deposited(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);


    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw() external {
        require(balances[msg.sender] > 0, "No balance to withdraw");
        
        uint256 amountToWithdraw = balances[msg.sender];
        balances[msg.sender] = 0;  // Set the balance to zero
        
        payable(msg.sender).transfer(amountToWithdraw);
        emit Withdrawn(msg.sender, amountToWithdraw);
    }


    function getBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    function closeBox() external {
        selfdestruct(payable(owner));
    }

    receive() external payable {
        // Accept incoming Ether without any specific action
    }
}