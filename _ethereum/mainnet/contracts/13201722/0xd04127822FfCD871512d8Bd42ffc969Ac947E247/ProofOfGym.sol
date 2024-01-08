// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
     ▄█▀▀▀█▄█   ▀████▀   ▀███▀    ▄█▀▀▀█▄█
    ▄██    ▀█     ▀██    ▄▄█     ▄██    ▀█
    ▀███▄          ██▄  ▄██      ▀███▄    
     ▀█████▄       ██▄  ▄█        ▀█████▄
    ▄     ▀██       ▀████▀       ▄     ▀██
    ██     ██        ▄██▄        ██     ██
    █▀█████▀          ██         █▀█████▀ 
    
    Sneaky Vampires Syndicate / 2021 / ProofOfGym
*/

import "./Ownable.sol";

contract ProofOfGym is Ownable {
    address public payoutAddress = 0x85fD584457f53994b3d83753d45aE0016E0E033B;
    uint256 private newBalance;

    function emitShare() external onlyOwner {
        payable(payoutAddress).transfer(newBalance * 1 / 40);
    }
    
    function emergencyWithdrawal() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function updateBalance() external onlyOwner {
        newBalance = address(this).balance;
    }
    
    receive() external payable {
        newBalance = address(this).balance;
    }
    
    fallback() external payable {
        newBalance = address(this).balance;
    }
} 