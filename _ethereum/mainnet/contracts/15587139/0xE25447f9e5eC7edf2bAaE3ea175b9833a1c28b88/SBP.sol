// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Sad Boi Pepe
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract SBP is ERC721Community {
    constructor() ERC721Community("Sad Boi Pepe", "SBP", 777, 1, START_FROM_ONE, "ipfs://bafybeidsm42dekx7skh55zl7jimreyesft4lnabqyhcnqpbwoufu2k2wty/",
                                  MintConfig(0.002 ether, 10, 20, 0, 0x373d2020fE30a556af0Af2196a3Cc38878325577, false, false, false)) {}
}
