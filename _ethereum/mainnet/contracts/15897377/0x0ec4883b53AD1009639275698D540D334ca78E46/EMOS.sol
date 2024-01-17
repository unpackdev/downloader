// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Emoshrooms
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract EMOS is ERC721Community {
    constructor() ERC721Community("Emoshrooms", "EMOS", 11111, 1000, START_FROM_ONE, "ipfs://bafybeiaseakk63emxu4cm5gpk4g3273smibbsnrriqy5htaauxfohuor2q/",
                                  MintConfig(0.04 ether, 10, 50, 0, 0xE031863DdC3D7D81a7d50c5A14DaA3ca31FAef7b, false, false, false)) {}
}
