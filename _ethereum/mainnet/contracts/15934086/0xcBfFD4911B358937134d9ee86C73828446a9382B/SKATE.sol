// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Skate or Die Pass
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract SKATE is ERC721Community {
    constructor() ERC721Community("Skate or Die Pass", "SKATE", 333, 20, START_FROM_ONE, "ipfs://bafybeid2n56hmlvd7vn6sdvlzta2eiwz6rksibgzdfwidl6wbt4sdhgysi/",
                                  MintConfig(0.01 ether, 5, 5, 0, 0xa47c7B6061edb2226A2E81C7C51d6349581743FF, false, false, false)) {}
}
