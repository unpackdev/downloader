// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Gary Troll

import "./ERC721Community.sol";

contract TROLL3 is ERC721Community {
    constructor() ERC721Community("Gary Troll", "TROLL3", 1000, 1, START_FROM_ONE, "ipfs://bafybeierznk2qgu2xxl3ast4z4cgu6e3rreaj4rayouv26gh2pqq5433gq/",
                                  MintConfig(10 ether, 10, 10, 0, 0x7d678e09B8F3668fe89434623D5c71EbfF8A6DF5, true, false, false)) {}
}
