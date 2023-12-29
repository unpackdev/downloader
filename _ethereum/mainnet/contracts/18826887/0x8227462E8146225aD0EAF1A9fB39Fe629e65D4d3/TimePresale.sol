// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// Created by dark-grey.eth
// Project: $TIME Memecoin [Presale]
// - Twitter: https://twitter.com/TimeMemecoin
// - Telegram: https://t.me/TIME_loundge
// - Website: www.time.cheap

contract TimePresale {
    address public owner;
    address public presaleWallet;
    bool public saleActive;

    enum SlotTier { Tier1, Tier2, Tier3 }

    struct TierInfo {
        uint256 maxParticipants;
        uint256 currentParticipants;
        uint256 entryFee;
    }

    mapping(SlotTier => TierInfo) public tiers;
    mapping(address => mapping(SlotTier => bool)) public hasPurchased;

    // Events
    event SlotPurchased(address indexed purchaser, SlotTier tier);
    event SaleStopped();
    event FundsWithdrawn(address indexed owner, uint256 amount);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier isSaleActive() {
        require(saleActive, "Presale is not active");
        _;
    }

    constructor(address _presaleWallet) {
        owner = msg.sender;
        presaleWallet = _presaleWallet;
        saleActive = true;

        // Initializing tier information
        tiers[SlotTier.Tier1] = TierInfo(20, 0, 0.25 ether);
        tiers[SlotTier.Tier2] = TierInfo(30, 0, 0.175 ether);
        tiers[SlotTier.Tier3] = TierInfo(50, 0, 0.1 ether);
    }

    function buySlot(SlotTier tier) external payable isSaleActive {
        TierInfo storage tierInfo = tiers[tier];
        require(tierInfo.currentParticipants < tierInfo.maxParticipants, "Tier is full");
        require(!hasPurchased[msg.sender][tier], "Already owns a slot in this tier");
        require(msg.value == tierInfo.entryFee, "Incorrect ETH amount");

        hasPurchased[msg.sender][tier] = true;
        tierInfo.currentParticipants++;

        // Automatic withdrawal if it's the last slot of the tier
        if (tierInfo.currentParticipants == tierInfo.maxParticipants) {
            autoWithdraw();
        }

        emit SlotPurchased(msg.sender, tier);
    }

    // Automatically withdraws funds to the presale wallet when the last slot of a tier is purchased
    function autoWithdraw() internal {
        uint256 balance = address(this).balance;
        (bool success, ) = presaleWallet.call{value: balance}("");
        require(success, "Transfer failed");
    }

    // Allows the owner to change the presale wallet address
    function setPresaleWallet(address _newWallet) external onlyOwner {
        presaleWallet = _newWallet;
    }

    // Allows the owner to stop the sale
    function stopSale() external onlyOwner {
        saleActive = false;
        emit SaleStopped();
    }

    // Allows the owner to withdraw funds from the contract
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds available");

        // Check-Effects-Interaction pattern to prevent reentrancy attacks
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");

        emit FundsWithdrawn(owner, balance);
    }

    // Returns the number of available slots in a given tier
    function availableSlots(SlotTier tier) external view returns (uint256) {
        return tiers[tier].maxParticipants - tiers[tier].currentParticipants;
    }
}