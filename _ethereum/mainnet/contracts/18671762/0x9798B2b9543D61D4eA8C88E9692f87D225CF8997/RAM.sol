// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC721SeaDropBurnable.sol";

contract RAM is ERC721SeaDropBurnable {

    constructor(
        string memory name,
        string memory symbol,
        address[] memory allowedSeaDrop
    ) ERC721SeaDropBurnable(name, symbol, allowedSeaDrop) {

    }
    
}
