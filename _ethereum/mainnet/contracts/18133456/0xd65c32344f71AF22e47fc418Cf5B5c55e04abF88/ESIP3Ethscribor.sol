// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.20;

contract ESIP3Ethscribor {
    uint256 public tokenId = 0;

    event ethscriptions_protocol_CreateEthscription(
        address indexed initialOwner,
        string contentURI
    );

    function ethscribe(string memory dataURI) public {
        unchecked {
            tokenId++;
        }
        
        emit ethscriptions_protocol_CreateEthscription(msg.sender, dataURI);
    }
}