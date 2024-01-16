// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Kawaii Mfers
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract KAMF is ERC721Community {
    constructor() ERC721Community("Kawaii Mfers", "KAMF", 1666, 10, START_FROM_ONE, "ipfs://bafybeid276sj626ggjuz5kh4i5c4t5xtbtrkzy47356qnkhcfr3smfmj4i/",
                                  MintConfig(0.009 ether, 10, 100, 0, 0x767d9a987cd98762E3a0A429eBC6698723BD14D5, false, false, false)) {}
}
