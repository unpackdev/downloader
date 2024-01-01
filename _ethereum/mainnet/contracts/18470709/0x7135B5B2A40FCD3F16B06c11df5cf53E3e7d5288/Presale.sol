// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Presale {
    address public owner;
    address private constant recipient = 0x59a26aC231937d8598F3cad8788f09E1bb3edf88;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        forwardFunds();
    }

    function forwardFunds() public payable {
        (bool success, ) = recipient.call{value: msg.value}("");
        require(success, "Failed to send Ether");
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Failed to withdraw funds");
    }
}