// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Scary Apes
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract SA is ERC721Community {
    constructor() ERC721Community("Scary Apes", "SA", 10000, 1, START_FROM_ONE, "ipfs://bafybeihqycuogiteuuzpfprzhatq4qh4liiu7lvpcsqzl2wguqaktspuju/",
                                  MintConfig(0.003 ether, 20, 20, 0, 0xc214c92a2ff0C81DD57B163412Dc80772C333b5F, false, false, false)) {}
}
