// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RoyaltySplitter {
    address payable public primaryRecipient;
    address payable public secondaryRecipient;
    uint256 public primaryShare; // The share for the primary recipient
    address public owner; // Owner of the contract

    // Event to log the change of recipients
    event RecipientsUpdated(address indexed primaryRecipient, address indexed secondaryRecipient);

    // Event to log the change of primary share
    event PrimaryShareUpdated(uint256 newShare);

    // Modifier to check if the caller is the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    constructor(address payable _primaryRecipient, address payable _secondaryRecipient, uint256 _primaryShare) {
        require(_primaryShare <= 100, "Primary share must be 100 or less");
        owner = msg.sender; // Set the contract deployer as the owner
        primaryRecipient = _primaryRecipient;
        secondaryRecipient = _secondaryRecipient;
        primaryShare = _primaryShare;
    }

    // Function to transfer ownership of the contract to a new address
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        owner = newOwner;
    }

    // Function to update the primary recipient address
    function setPrimaryRecipient(address payable _newPrimaryRecipient) external onlyOwner {
        primaryRecipient = _newPrimaryRecipient;
        emit RecipientsUpdated(primaryRecipient, secondaryRecipient);
    }

    // Function to update the secondary recipient address
    function setSecondaryRecipient(address payable _newSecondaryRecipient) external onlyOwner {
        secondaryRecipient = _newSecondaryRecipient;
        emit RecipientsUpdated(primaryRecipient, secondaryRecipient);
    }

    // Function to update the primary share percentage
    function setPrimaryShare(uint256 _newPrimaryShare) external onlyOwner {
        require(_newPrimaryShare <= 100, "Primary share must be 100 or less");
        primaryShare = _newPrimaryShare;
        emit PrimaryShareUpdated(primaryShare);
    }

    // Function to split the incoming funds
    function splitFunds() public payable {
        uint256 primaryAmount = (msg.value * primaryShare) / 100;
        uint256 secondaryAmount = msg.value - primaryAmount;

        (bool sentPrimary, ) = primaryRecipient.call{value: primaryAmount}("");
        require(sentPrimary, "Failed to send Ether to primary recipient");

        (bool sentSecondary, ) = secondaryRecipient.call{value: secondaryAmount}("");
        require(sentSecondary, "Failed to send Ether to secondary recipient");
    }

    // Fallback function to handle direct ether transfers
    fallback() external payable {
        splitFunds();
    }

    // Function to receive funds and split them accordingly
    receive() external payable {
        splitFunds();
    }
}