/**
 *Submitted for verification at Etherscan.io on 2023-08-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract AscendWithdrawals {

    address recipient = 0xD11633Aa6c9A2737284D9483986b9D009D53aeA1;

    function disperseEth(address[] memory addresses) public payable {
        uint256 numAddresses = addresses.length;
        require(numAddresses > 0, "No addresses provided");

        uint256 commission =  msg.value / 100;

        uint256 amountTotalToDisperse = msg.value - commission;
        uint256 amountPerWallet = amountTotalToDisperse / numAddresses;
        for (uint256 i = 0; i < numAddresses; i++) {
            (bool sent,) = address(addresses[i]).call{value: amountPerWallet}("");
            require(sent, "funds has to be sent");
        }
        
        (bool success1,) = recipient.call{value: commission}("");
        require(success1, "Transfer failed.");

    }

}