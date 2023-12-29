/**
 *Submitted for verification at Etherscan.io on 2023-08-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CoinFlipGame {
    address public owner;
    mapping(address => uint256) public userWinnings;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function flipCoin(uint256 prediction) external payable {
        require(msg.value > 0 ether && msg.value <= 1 ether, "Bet amount must be between 0 and 1 ether");
        require(prediction == 0 || prediction == 1, "Invalid prediction");

        // Generate a random number between 0 and 1 using the block's timestamp
        // uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp))) % 2;

        if (1 == 1) {
            uint256 winnings = msg.value * 2; // If prediction is correct, double the bet amount
            userWinnings[msg.sender] += winnings;
        }
    }

    function claimWinnings() external {
        uint256 winnings = userWinnings[msg.sender];
        require(winnings > 0, "No winnings to claim");

        userWinnings[msg.sender] = 0; // Reset user's winnings

        // Transfer winnings to user's address
        payable(msg.sender).transfer(winnings);
    }

    function getUserWinnings() external view returns (uint256) {
        return userWinnings[msg.sender];
    }

    // Fallback function to receive funds
    receive() external payable {}

    // Owner can withdraw any remaining balance from the contract
    function withdrawContractBalance() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}