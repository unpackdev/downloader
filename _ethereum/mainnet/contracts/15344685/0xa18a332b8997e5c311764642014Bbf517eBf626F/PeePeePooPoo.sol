// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./ERC721A.sol";
import "./Ownable.sol";

/*
    ░░░░░░░░░░░█▀▀░░█░░░░░░
    ░░░░░░▄▀▀▀▀░░░░░█▄▄░░░░
    ░░░░░░█░█░░░░░░░░░░▐░░░
    ░░░░░░▐▐░░░░░░░░░▄░▐░░░
    ░░░░░░█░░░░░░░░▄▀▀░▐░░░
    ░░░░▄▀░░░░░░░░▐░▄▄▀░░░░
    ░░▄▀░░░▐░░░░░█▄▀░▐░░░░░
    ░░█░░░▐░░░░░░░░▄░█░░░░░
    ░░░█▄░░▀▄░░░░▄▀▐░█░░░░░
    ░░░█▐▀▀▀░▀▀▀▀░░▐░█░░░░░
    ░░▐█▐▄░░▀░░░░░░▐░█▄▄░░░
    ░░░▀▀░▄QTPie▄░░▐▄▄▄▀░░░░
*/

contract PeePeePooPoo is ERC721A, Ownable {
    uint256 public MAX_PEEPEEPOOPOO = 100000;

    constructor() ERC721A("Pee Pee Poo Poo", "PPPOOPOO") Ownable() {}

    function _baseURI() internal view virtual override returns (string memory) {
        return
            "ipfs://bafkreiexzwhjurxnop2ldfc5rirolxncmclkoju65bnmhylulhqf7f6wwu";
    }

    function mint() external payable onlyOwner {
        require(totalSupply() < MAX_PEEPEEPOOPOO, "Mint already completed");
        _mint(msg.sender, 5000);
    }
}
