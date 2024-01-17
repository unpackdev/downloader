// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: M3Bverse
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract M3B is ERC721Community {
    constructor() ERC721Community("M3Bverse", "M3B", 4444, 54, START_FROM_ONE, "ipfs://bafybeibh6wg2iz57fd7krnxg5nyk3wtsfktzq2nopn2tl22m4dwfyyre74/",
                                  MintConfig(0.0055 ether, 2, 2, 0, 0xe23789DF25c36AF1162Cf3f6E88B0E984CA264c6, false, false, false)) {}
}
