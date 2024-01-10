// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721E.sol";

contract Osashimi is ERC721E {
    constructor()
    ERC721E("Osashimi", "OSSM") {}
}
