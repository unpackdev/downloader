// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC1155.sol";

contract ERC1155Basic is ERC1155 {
    string public name = "123";
    string public symbol = "321";

    constructor()

    ERC1155( "https://xorad.shop/test/{id}" )
    {
        _mint(msg.sender, 0, 10, "1");
        _mint(msg.sender, 1, 10, "2");
        _mint(msg.sender, 2, 10, "3");
        _mint(msg.sender, 3, 10, "1");
        _mint(msg.sender, 4, 10, "2");
        _mint(msg.sender, 5, 10, "3");
        _mint(msg.sender, 6, 10, "1");
        _mint(msg.sender, 7, 10, "2");
        _mint(msg.sender, 8, 10, "3");
        _mint(msg.sender, 9, 10, "1");
    }
}
