// SPDX-License-Identifier: MIT

// GhostDAG.org
// Miner Funding Wallet from GDAG Tax redirects


pragma solidity ^0.8.0;

contract MinerFunding {
    address payable public specificAddress;

    constructor() {
        specificAddress = payable(0xD7D849926Cd5c0418be1e96d0e370e247C8F9aeB);
    }

    receive() external payable {
    }

    function withdraw() external {
        require(msg.sender == specificAddress, "Only specific address can withdraw");
        specificAddress.transfer(address(this).balance);
    }
}