//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

//simple payments handling for splitting between fixed wallets
contract PaymentsShared is Ownable, ReentrancyGuard {

    address WalletA = 0x0939D5c0DAb578ae7DA3cf11bfd4b7e5dc53CD45;
    address WalletB = 0x670c38d686DA822bcc96c565ceE1DD7E007D1544;
    address WalletC = 0x42D2339cA21C7D5df409326068c5CE5975dB5A39;
    address WalletD = 0xBa643BE38D25867E2062890ee5D42aA6879F5586;

    //payments
    function withdrawAll() external nonReentrant onlyOwner {          

        uint256 ticks = address(this).balance / 1000;

        (bool success, ) = WalletA.call{value: ticks * 250}(""); //25%
        require(success, "Transfer failed.");

        payable(WalletB).transfer(ticks * 100); //10%
        payable(WalletC).transfer(ticks * 325); //32.5%
        payable(WalletD).transfer(address(this).balance); //32.5%
    }

    function withdrawSafety() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

}