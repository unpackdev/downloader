// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error MultiSender__NotOwner();
error MultiSender__InvalidNumberOfRecipients();
error MultiSender__NotEnoughBalance();

contract MultiSender {
    address private owner;

    uint public total_value_locked;

    event OwnerChanged(address indexed newOwner, address indexed oldOwner);
    event AccountRecharged(uint256 rechargeValue);

    modifier isOwner() {
        if (msg.sender != owner) {
            revert MultiSender__NotOwner();
        }
        _;
    }

    constructor() payable {
        owner = msg.sender;
        total_value_locked = msg.value;
    }

    function changeOwner(address newOwner) public isOwner {
        emit OwnerChanged(newOwner, owner);
        owner = newOwner;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function recharge() public payable isOwner {
        total_value_locked += msg.value;
        emit AccountRecharged(msg.value);
    }

    function sendToMany(
        address payable[] memory recipients,
        uint[] memory amounts
    ) public payable isOwner {
        total_value_locked += msg.value;

        if (recipients.length != amounts.length) {
            revert MultiSender__InvalidNumberOfRecipients();
        }

        uint totalAmountToSend = 0;
        for (uint i = 0; i < amounts.length; i++) {
            totalAmountToSend += amounts[i];
        }

        if (totalAmountToSend > total_value_locked) {
            revert MultiSender__NotEnoughBalance();
        }

        // Now send to multiple recipients
        for (uint i = 0; i < recipients.length; i++) {
            total_value_locked -= amounts[i];
            recipients[i].transfer(amounts[i]);
        }
    }
}