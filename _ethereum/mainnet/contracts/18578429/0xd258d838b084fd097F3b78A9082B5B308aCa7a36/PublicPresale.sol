// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract PublicPresale {
    address public owner;
    address public presaleWallet;
    uint256 public maxParticipants;
    uint256 public currentParticipants;
    bool public saleActive;
    uint256 public entryFee;

    mapping(address => bool) public participantAddresses;

    // Events
    event SlotPurchased(address purchaser);
    event SaleStopped();
    event FundsWithdrawn(address owner, uint256 amount);

    constructor(uint256 _maxParticipants, uint256 _entryFee, address _presaleWallet) {
        owner = msg.sender;
        maxParticipants = _maxParticipants;
        entryFee = _entryFee;
        saleActive = true;
        currentParticipants = 0;
        presaleWallet = _presaleWallet;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier isSaleActive() {
        require(saleActive, "The presale has been stopped");
        _;
    }

    function buySlot() external payable isSaleActive {
        require(currentParticipants < maxParticipants, "No more slots available");
        require(!participantAddresses[msg.sender], "Address already holds a slot");
        require(msg.value == entryFee, "Incorrect ETH sent");

        participantAddresses[msg.sender] = true;
        currentParticipants++;

        emit SlotPurchased(msg.sender);
    }

    function stopSale() external onlyOwner {
        saleActive = false;
        emit SaleStopped();
    }

    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        payable(owner).transfer(balance);
        emit FundsWithdrawn(owner, balance);
    }

    function setPresaleWallet(address _newPresaleWallet) external onlyOwner {
        presaleWallet = _newPresaleWallet;
    }

    function availableSlots() external view returns (uint256) {
        return maxParticipants - currentParticipants;
    }
}
