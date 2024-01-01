// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IERC20.sol";

contract TestExchange {
    address public owner;
    address public treasury;
    address public customTokenAddress; // Address of the custom ERC-20 token
    address public baseTokenAddress; // Address of payment token e.x USDT
    // address public wethAddress = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14; // mainnet -> 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function"
        );
        _;
    }

    // Constructor to initialize the contract
    constructor(
        address _treasury,
        address _customTokenAddress,
        address _baseTokenAddress
    ) {
        owner = msg.sender;
        treasury = _treasury;
        customTokenAddress = _customTokenAddress;
        baseTokenAddress = _baseTokenAddress;
    }

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Address should be valid");
        treasury = _treasury;
    }

    function setCustomTokenAddress(address _token) external onlyOwner {
        require(_token != address(0), "Address should be valid");
        customTokenAddress = _token;
    }

    function setBaseTokenAddress(address _token) external onlyOwner {
        require(_token != address(0), "Address should be valid");
        baseTokenAddress = _token;
    }

    // Function to receive and swap tokens
    function pay(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");

        // Transfer the user's ERC-20 token (e.g., USDT) to this contract
        // Ensure the sender has approved the contract to spend their tokens
        require(
            IERC20(baseTokenAddress).transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            "Transfer failed"
        );

        // Transfer the received tokens to the treasury
        require(
            IERC20(baseTokenAddress).transfer(treasury, amount),
            "Treasury transfer failed"
        );

        // Transfer custom tokens back to the sender
        require(
            IERC20(customTokenAddress).transfer(msg.sender, amount),
            "Custom token transfer failed"
        );
    }
}
