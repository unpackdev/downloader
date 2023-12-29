// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: AI SMOKE
// contract by: buildship.xyz

import "./ERC721Community.sol";

contract AIS is ERC721Community {
    constructor() ERC721Community("AI SMOKE", "AIS", 1000, 1, START_FROM_ONE, "ipfs://bafybeiaixnbbrqtfqid3orytisxr5dxmdgnr3sqw4qmsrzsepbvcxyyoq4/",
                                  MintConfig(0.04 ether, 6, 6, 0, 0x30398240A58613F3ca65360EA7e2F62a5fD40969, false, false, false)) {}
}
