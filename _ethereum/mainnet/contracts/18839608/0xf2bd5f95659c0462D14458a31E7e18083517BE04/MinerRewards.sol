// SPDX-License-Identifier: MIT

// GhostDAG.org
// Holds KAS earned (in ETH) from GDAG Miners


pragma solidity ^0.8.0;

contract MinerRewards {
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