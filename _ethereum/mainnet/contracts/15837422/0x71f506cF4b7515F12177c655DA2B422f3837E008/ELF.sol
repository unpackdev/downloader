// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: ikigai
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract ELF is ERC721Community {
    constructor() ERC721Community("ikigai", "ELF", 7000, 1, START_FROM_ONE, "ipfs://bafybeibyzpohavbjz6h7crpmwajj3svedi62pivnkri5ud4nfrae5qpgxy/",
                                  MintConfig(0.015 ether, 5, 5, 0, 0x323421A2EedF46844E30F640bBDf62c98c8b3ab9, false, false, false)) {}
}
