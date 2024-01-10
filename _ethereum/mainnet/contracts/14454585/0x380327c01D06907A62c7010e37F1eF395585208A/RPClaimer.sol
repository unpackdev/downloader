// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "Ownable.sol";

// Created By halfshadow.eth
// Twitter Username 0xhalfshadow
// Message From Creator: This is a contract deploy to save Raid Party user time for them to claim multiple account at once
// You Can Donate to my ens wallet which is *** halfshadow.eth *** to
// Support the deploy of code and Development of Website, and My further digging into gas saving strategy for Raid Party and Future Games

interface IRaidParty {
    function claimRewards(address user) external;
}

contract RPClaimer is Ownable {
    IRaidParty public RaidPartyContract;

    constructor(address _RaidParty) {
        RaidPartyContract = IRaidParty(_RaidParty);
    }

    function setRaidParty(address _RaidParty) external onlyOwner {
        RaidPartyContract = IRaidParty(_RaidParty);
    }

    function claimMultiple(address[] calldata users) external {
        for (uint256 i = 0; i < users.length; i++) {
            RaidPartyContract.claimRewards(users[i]);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
