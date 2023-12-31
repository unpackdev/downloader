// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Troll 5

import "./ERC721Community.sol";

contract TROLL5 is ERC721Community {
    constructor() ERC721Community("Troll 5", "TROLL5", 10000, 1, START_FROM_ONE, "ipfs://bafybeia4n7de4jngywca6oawsvduputccaaiipotddhyk62mvwqbybige4/",
                                  MintConfig(0.05 ether, 20, 20, 0, 0x7d678e09B8F3668fe89434623D5c71EbfF8A6DF5, true, false, false)) {}
}
