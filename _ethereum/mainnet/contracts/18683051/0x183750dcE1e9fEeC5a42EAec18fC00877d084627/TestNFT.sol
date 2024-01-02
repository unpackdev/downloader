// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./ERC721.sol";

contract TestNFT is ERC721 {
    constructor(uint256 premint_) ERC721('NFT', 'NFT') {
        for (uint256 i = 0; i < premint_; i++) {
            _mint(msg.sender, i);
        }
    }
}
