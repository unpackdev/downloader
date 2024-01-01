// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Children at War
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract CAW is ERC721Community {
    constructor() ERC721Community("Children at War", "CAW", 3999, 399, START_FROM_ONE, "ipfs://bafybeicgicfr3xwz6fufreivjodr5yffdgcos32kzdwiwxtb7ncsy6sbye/",
                                  MintConfig(0.1 ether, 10, 10, 0, 0x4590DFBD5Ee8A7847b1B23fDc0E434C0094F7722, false, false, false)) {}
}
