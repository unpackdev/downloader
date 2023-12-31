// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: BlueBoy
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract BBT is ERC721Community {
    constructor() ERC721Community("BlueBoy", "BBS", 10000, 1, START_FROM_ONE, "ipfs://bafybeibpac7afi73joz5p4lx57kvw4e3i2id7kcvo2v7mfgaeyl7rzbf54/",
                                  MintConfig(0.1 ether, 20, 20, 0, 0xa804F688D9De9D3b5149D053001965a2E6404AaB, false, false, false)) {}
}
