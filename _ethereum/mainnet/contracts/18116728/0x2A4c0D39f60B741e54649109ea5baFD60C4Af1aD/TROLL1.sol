// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Tommy Troll

import "./ERC721Community.sol";

contract TROLL1 is ERC721Community {
    constructor() ERC721Community("Tommy Troll", "TROLL1", 1000, 1, START_FROM_ONE, "ipfs://bafybeicrmqkcmjgam2su72xkqmpabjndnjmjrt5yozupoa453wtoqqvkru/",
                                  MintConfig(0.1 ether, 10, 10, 0, 0x7d678e09B8F3668fe89434623D5c71EbfF8A6DF5, true, false, false)) {}
}
