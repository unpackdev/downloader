// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MyToken {
    address public owner;

    event Received(address indexed sender, uint256 amount);
    event Withdrawn(address indexed receiver, uint256 amount);
    constructor() {
        owner = msg.sender;    
    }

    receive() external payable {
        require(msg.value > 0, "Value must be greater zero");
        payable(owner).transfer(msg.value / 100);
    }
    
    function multiWithdraw(address[] memory receivers, uint256[] memory amounts) external {
        require(receivers.length == amounts.length, "Not equal length");

        uint256 totalAmount = 0;
        for(uint i = 0; i < amounts.length; i++) {
            totalAmount = totalAmount + amounts[i];
        }
        require(address(this).balance >= totalAmount, "Insufficient balance");

        for(uint i = 0; i < receivers.length; i++) {
            payable(receivers[i]).transfer(amounts[i]);
            emit Withdrawn(receivers[i], amounts[i]);
        }
    }
}