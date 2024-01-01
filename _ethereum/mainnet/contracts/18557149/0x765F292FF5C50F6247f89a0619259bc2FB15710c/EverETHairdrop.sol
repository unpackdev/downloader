// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Welcome to EverETH.
 
  _____                _____ _____ _   _ 
 | ____|_   _____ _ __| ____|_   _| | | |
 |  _| \ \ / / _ \ '__|  _|   | | | |_| |
 | |___ \ V /  __/ |  | |___  | | |  _  |
 |_____| \_/ \___|_|  |_____| |_| |_| |_|
                                         
                                                           
 * Official website: EverETH.net
 */

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract EverETHairdrop {
    address public owner;
    address public tokenAddress;
    uint256 public totalTokens;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    constructor(address _tokenAddress) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
    }

    function setTokenAddress(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0), "Invalid token address.");
        tokenAddress = _tokenAddress;
    }

    function setTotalTokens(uint256 _totalTokens) external onlyOwner {
        totalTokens = _totalTokens;
    }

    function distributeTokens(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Number of recipients must match the number of amounts.");

        uint256 tokenBalance = IERC20(tokenAddress).balanceOf(address(this));
        require(tokenBalance >= totalTokens, "Insufficient tokens in the contract.");

        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address.");

            uint256 amount = amounts[i];
            require(amount <= totalTokens, "Amount exceeds the total tokens allocated for airdrop.");

            require(IERC20(tokenAddress).transfer(recipients[i], amount), "Token transfer failed.");

            totalTokens -= amount;
        }
    }

    function withdrawTokens(uint256 amount) external onlyOwner {
        require(amount <= IERC20(tokenAddress).balanceOf(address(this)), "Insufficient tokens in the contract.");
        require(IERC20(tokenAddress).transfer(owner, amount), "Token transfer failed.");
    }

    function withdrawTokensRemaining() external onlyOwner {
        require(totalTokens > 0, "No remaining tokens to withdraw.");
        require(IERC20(tokenAddress).transfer(owner, totalTokens), "Token transfer failed.");
        totalTokens = 0;
    }
}