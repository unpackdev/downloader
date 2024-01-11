// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC1155.sol";

contract ERC1155Basic is ERC1155 {
    string public name = "Testing NFT Bored Hamster 2";
    string public symbol = "TST";

    constructor()

    ERC1155( "https://xorad.shop/test2/{id}" )
    {
        _mint(msg.sender, 0, 20, "");
        _mint(msg.sender, 1, 20, "");
        _mint(msg.sender, 2, 20, "");
        _mint(msg.sender, 3, 20, "");
        _mint(msg.sender, 4, 20, "");
        _mint(msg.sender, 5, 20, "");
        _mint(msg.sender, 6, 20, "");
        _mint(msg.sender, 7, 20, "");
        _mint(msg.sender, 8, 20, "");
        _mint(msg.sender, 9, 20, "");

        _mint(msg.sender, 10, 2, "");
        _mint(msg.sender, 11, 2, "");
        _mint(msg.sender, 12, 2, "");
        _mint(msg.sender, 13, 2, "");
        _mint(msg.sender, 14, 2, "");
        _mint(msg.sender, 15, 2, "");
        _mint(msg.sender, 16, 2, "");
        _mint(msg.sender, 17, 2, "");
        _mint(msg.sender, 18, 2, "");
        _mint(msg.sender, 19, 2, "");

        _mint(msg.sender, 20, 1, "");
        _mint(msg.sender, 21, 1, "");
        _mint(msg.sender, 22, 1, "");
        _mint(msg.sender, 23, 1, "");
        _mint(msg.sender, 24, 1, "");
        _mint(msg.sender, 25, 1, "");
        _mint(msg.sender, 26, 1, "");
        _mint(msg.sender, 27, 1, "");
        _mint(msg.sender, 28, 1, "");
        _mint(msg.sender, 29, 1, "");
    }
}
