// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract CTD_msg {
    address public owner;

    event Deposited(address indexed sender, uint256 amount, uint256 timestamp);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // Fallback function to receive ETH
    receive() external payable {
        emit Deposited(msg.sender, msg.value, block.timestamp);
    }

    // Function to withdraw all balance by the owner
    function withdraw() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No funds to withdraw");
        payable(owner).transfer(contractBalance);
    }
}