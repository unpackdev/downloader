// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Tradable.sol";

/**
 * @title BlueUnited
 * BlueUnited - a contract for Stredium Accessory semi-fungible tokens.
 */
contract BlueUnited is ERC1155Tradable {

    uint256 public constant NFT1 = 0;
    uint256 public constant NFT2 = 1;
    uint256 public constant NFT3 = 2;
    uint256 public constant NFT4 = 3;
    uint256 public constant NFT5 = 4;
    uint256 public constant NFT6 = 5;
    
    constructor(address _proxyRegistryAddress)
        ERC1155Tradable(
            "Stredium - Blue United Moments",
            "STREDIUM",
            "https://storageapi.fleek.co/stredium-team-bucket/blueunited/{id}.json",
            _proxyRegistryAddress
        ) {
        create(msg.sender, NFT1, 50, '', '0x0');
        create(msg.sender, NFT2, 50, '', '0x1');
        create(msg.sender, NFT3, 50, '', '0x2');
        create(msg.sender, NFT4, 50, '', '0x3');
        create(msg.sender, NFT5, 20, '', '0x4');
        create(msg.sender, NFT6, 20, '', '0x5');
    }

    function contractURI() public pure returns (string memory) {
        return "https://storageapi.fleek.co/stredium-team-bucket/blueunited/metadata.json"; 
    }
}
