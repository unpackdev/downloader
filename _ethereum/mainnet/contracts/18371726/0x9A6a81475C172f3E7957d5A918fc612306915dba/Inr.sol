// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract INR is ERC20, Ownable {
    event TokensPurchased(address indexed buyer, uint256 amount, uint256 cost);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        // Mint initial supply and assign to the contract creator (msg.sender)
        _mint(msg.sender, 1_00_00_000 * 10 ** decimals());
    }

    // A function to allow users to buy tokens with ETH
    function buy() external payable {
        require(msg.value > 0, "Value sent must be greater than 0");

        // Calculate the amount of tokens to mint based on the ETH sent
        uint256 tokensToMint = (msg.value * 10 ** decimals()) / 1000000000; // Adjust the conversion rate

        // Mint tokens and transfer to the buyer
        _mint(msg.sender, tokensToMint);

        // Emit an event to log the purchase
        emit TokensPurchased(msg.sender, tokensToMint, msg.value);
    }

    // A function to withdraw ETH from the contract (only the owner can call this)
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
