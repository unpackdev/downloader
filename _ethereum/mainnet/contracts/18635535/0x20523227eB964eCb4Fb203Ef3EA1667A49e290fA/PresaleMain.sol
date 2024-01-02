// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract PresaleMain {
    address public owner;
    address public presaleWallet;
    uint256 public maxParticipants;
    uint256 public currentParticipants;
    bool public saleActive;
    uint256 public entryFee;

    mapping(address => bool) public kolAddresses;

    event KolSlotPurchased(address purchaser);
    event SaleStopped();
    event FundsWithdrawn(address recipient, uint256 amount);

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

        function buyKolSlot() external payable isSaleActive {
        require(currentParticipants < maxParticipants, "No more slots available");
        require(!kolAddresses[msg.sender], "Address already holds a KOL slot");
        require(msg.value == entryFee, "Incorrect ETH sent");

        kolAddresses[msg.sender] = true;
        currentParticipants++;

        emit KolSlotPurchased(msg.sender);
    }

    function stopSale() external onlyOwner {
        saleActive = false;
        emit SaleStopped();
    }

    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        payable(presaleWallet).transfer(balance);
        emit FundsWithdrawn(presaleWallet, balance);
    }

    function setPresaleWallet(address _newPresaleWallet) external onlyOwner {
        presaleWallet = _newPresaleWallet;
    }

    function availableSlots() external view returns (uint256) {
        return maxParticipants - currentParticipants;
    }
}