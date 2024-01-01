// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUSDC {
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
}

contract ReviewsRewards {
    // USDC token contract address
    address public usdcAddress;
    address public owner;
    IUSDC public usdc;

    // Mapping of user's address to their earned amount
    mapping(address => uint256) public earnedAmounts;

    constructor(address _usdcAddress) {
        usdcAddress = _usdcAddress;
        usdc = IUSDC(_usdcAddress);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    function depositUSDC(uint256 amount) external onlyOwner {
        require(
            usdc.transferFrom(msg.sender, address(this), amount),
            "Transfer failed."
        );
    }

    function recordEarnings(address user, uint256 amount) external onlyOwner {
        earnedAmounts[user] += amount;
    }

    function withdraw(uint256 amount) external {
        require(
            earnedAmounts[msg.sender] >= amount,
            "Not enough earned funds."
        );

        earnedAmounts[msg.sender] -= amount;
        require(usdc.transfer(msg.sender, amount), "Transfer failed.");
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address.");
        owner = newOwner;
    }
}