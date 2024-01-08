// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721URIStorage.sol";

contract BTCSDavosNft is ERC721URIStorage {
    uint256 public constant COIN = 0;

    constructor(string memory name, string memory symbol, string memory uri) public ERC721(name, symbol) {
        _mint(msg.sender, COIN);
        _setTokenURI(COIN, uri);
    }
}